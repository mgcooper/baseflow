function tests = test_corechain
   %TEST_CORECHAIN Core-workflow coverage for the analysis chain.
   %
   % The other core-chain functions (getevents, fitevents, fitab,
   % eventfinder) have coverage in TestBaseflow, test_fitopts, and the
   % smoke script. This file tests eventtau, globalfit, and fitphi on the
   % example data, and gpfitb, fitphidist, and aQbString on synthetic
   % inputs. The chain runs once on the shipped example data in setupOnce;
   % the constants are the Kuparuk basin values the demos use.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Run the example-data chain once; event fitting is the slow part.
   [T, Q, R] = baseflow.loadExampleData();
   Events = baseflow.getevents(T, Q, R, baseflow.setopts('getevents'));
   [Fits, FitsTable] = baseflow.fitevents(Events, ...
      baseflow.setopts('fitevents'));
   testCase.TestData.Events = Events;
   testCase.TestData.Fits = Fits;
   testCase.TestData.FitsTable = FitsTable;

   % Kuparuk basin constants from the demos.
   A = 8.6545e9;
   D = 0.5;
   drainagedensity = 0.8;
   testCase.TestData.A = A;
   testCase.TestData.D = D;
   testCase.TestData.drainagedensity = drainagedensity;
   testCase.TestData.L = A*drainagedensity/1000;

   % Name the fitphi recession inputs that two tests share: the early-time
   % and late-time a values and the linear (b = 1) late-time exponent.
   testCase.TestData.a1 = 1e-12;
   testCase.TestData.a2 = 1.05e-3;
   testCase.TestData.b2_linear = 1;

   % phi is a drainable porosity, so a plausible value lies in (0, 1).
   testCase.TestData.phimin = 0;
   testCase.TestData.phimax = 1;
end

function test_eventtauNominal(testCase)
   % eventtau returns aligned, positive drainage timescales with valid
   % event tags on the example-data fits.
   mintaucount = 100;
   [tau_returned, q_returned, dqdt_returned, tags_returned] = ...
      baseflow.eventtau(testCase.TestData.FitsTable, ...
      testCase.TestData.Events, testCase.TestData.Fits);
   testCase.assertGreaterThan(numel(tau_returned), mintaucount)

   % q, dqdt, and tags have one element per tau value. Event tags start
   % at 1.
   sizes_returned = [numel(q_returned), numel(dqdt_returned), ...
      numel(tags_returned)];
   sizes_expected = repmat(numel(tau_returned), 1, 3);
   testCase.verifyEqual(sizes_returned, sizes_expected)
   testCase.verifyTrue(all(tau_returned > 0 & isfinite(tau_returned)))
   testCase.verifyTrue(all(tags_returned >= 1))
end

function test_globalfitNominal(testCase)
   % globalfit produces physically plausible global parameters on the
   % example data. Limitation: the default 'pointcloud' phi method
   % estimates phi through pointcloudplot, which always draws. One figure
   % appears even with plotfits false (TODO.md records the refactor). The
   % teardown closes it.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   bmin = 1;
   bmax = 2;
   phimin = testCase.TestData.phimin;
   phimax = testCase.TestData.phimax;
   gopts = baseflow.setopts('globalfit', ...
      'drainagearea', testCase.TestData.A, ...
      'drainagedensity', testCase.TestData.drainagedensity, ...
      'streamlength', testCase.TestData.L, ...
      'aquiferdepth', testCase.TestData.D, ...
      'isflat', true, 'plotfits', false, 'bootfit', false);
   returned = baseflow.globalfit(testCase.TestData.FitsTable, ...
      testCase.TestData.Events, testCase.TestData.Fits, gopts);

   % a and tau0 are positive, b lies in (bmin, bmax), and phi lies in
   % (phimin, phimax).
   testCase.verifyGreaterThan(returned.a, 0)
   testCase.verifyGreaterThan(returned.b, bmin)
   testCase.verifyLessThan(returned.b, bmax)
   testCase.verifyGreaterThan(returned.tau0, 0)
   testCase.verifyGreaterThan(returned.phi, phimin)
   testCase.verifyLessThan(returned.phi, phimax)
   newfigs_returned = numel(findall(0, 'Type', 'figure')) - numel(figsbefore);
   newfigs_expected = 1;
   testCase.verifyLessThanOrEqual(newfigs_returned, newfigs_expected)
end

function test_fitphiNominal(testCase)
   % The PK62 early / BS03 late (b=1) pair returns one interior phi with
   % its description; the default RS05 pair returns an interior phi for
   % the fitted late-time exponent range.
   A = testCase.TestData.A;
   D = testCase.TestData.D;
   L = testCase.TestData.L;
   a1 = testCase.TestData.a1;
   a2 = testCase.TestData.a2;
   b2_linear = testCase.TestData.b2_linear;
   b2_fitted = 1.278;
   solns_expected = {'PK62_BS03'};
   ndesc_expected = 2;
   phimin = testCase.TestData.phimin;
   phimax = testCase.TestData.phimax;

   [phi_returned, solns_returned, desc_returned] = baseflow.fitphi( ...
      a1, a2, b2_linear, A, D, L, 'soln1', 'PK62', 'soln2', 'BS03');
   testCase.verifyEqual(solns_returned, solns_expected)
   testCase.verifyNumElements(desc_returned, ndesc_expected)
   testCase.verifyGreaterThan(phi_returned, phimin)
   testCase.verifyLessThan(phi_returned, phimax)

   phi_returned = baseflow.fitphi(a1, a2, b2_fitted, A, D, L);
   testCase.verifyGreaterThan(phi_returned, phimin)
   testCase.verifyLessThan(phi_returned, phimax)
end

function test_gpfitbNominal(testCase)
   % gpfitb recovers the known parameters of a synthetic Pareto sample
   % (pdf exponent 2.5: b = 1.4, k = 2/3, tau0 = xmin = 1) with no
   % figures when the plot and bootstrap options are off. The default
   % call runs private/ccdf.m, which must read the makeplot option as
   % p.Results.makeplot; a read of p.makeplot errors.
   figsbefore = findall(0, 'Type', 'figure');
   nsamples = 5000;
   pdfexponent = 2.5;
   xmin = 1;
   b_expected = 1.4;
   k_expected = 2/3;
   tau0_expected = xmin;
   nfigs_expected = numel(figsbefore);
   tol = 0.02;
   tau0tol = 0.05;

   % Inverse-CDF sample at midpoint probabilities: ccdf exponent is
   % pdfexponent - 1.
   u = ((1:nsamples)' - 0.5)/nsamples;
   x = (1 - u).^(-1/(pdfexponent - 1));
   returned = baseflow.gpfitb(x, 'xmin', xmin, ...
      'plotfit', false, 'bootfit', false);
   nfigs_returned = numel(findall(0, 'Type', 'figure'));
   testCase.verifyEqual(returned.b, b_expected, 'AbsTol', tol)
   testCase.verifyEqual(returned.k, k_expected, 'AbsTol', tol)
   testCase.verifyEqual(returned.tau0, tau0_expected, 'AbsTol', tau0tol)
   testCase.verifyEqual(nfigs_returned, nfigs_expected)
end

function test_fitphidistNominal(testCase)
   % fitphidist recovers the mean of a synthetic phi sample. The function
   % draws its distribution figure by design (every plottype produces
   % one), so the teardown closes it.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   nsamples = 500;
   phimean = 0.05;
   phistd = 0.01;
   phifloor = 1e-3;
   phiceil = 0.2;
   showfit = false;
   expected = phimean;
   tol = 0.005;
   phid = min(max(phimean + phistd*randn(nsamples, 1), phifloor), phiceil);
   returned = baseflow.fitphidist(phid, 'mean', 'cdf', showfit);
   testCase.verifyEqual(returned, expected, 'AbsTol', tol)
end

function test_aQbStringNominal(testCase)
   % aQbString builds the latex label for the recession equation.
   ab = [1e-2 1.5];
   returned = baseflow.aQbString(ab);
   expected = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';
   testCase.verifyEqual(returned, expected)
end

function test_fitphiUnsupportedPairErrors(testCase)
   % b2 = 1 with the default RS05 solutions remaps to a pair with no
   % derived formula; the guard raises the documented error instead of
   % returning unassigned outputs.
   a1 = testCase.TestData.a1;
   a2 = testCase.TestData.a2;
   b2_linear = testCase.TestData.b2_linear;
   expected = 'baseflow:fitphi:unsupportedSolution';
   testCase.verifyError(@() baseflow.fitphi(a1, a2, b2_linear, ...
      testCase.TestData.A, testCase.TestData.D, testCase.TestData.L), ...
      expected)
end
