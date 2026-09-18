function tests = test_corechain
   %TEST_CORECHAIN Core-workflow coverage for the analysis chain.
   %
   % The other core-chain functions (getevents, fitevents, fitab,
   % eventfinder) have coverage in TestBaseflow, test_fitopts, and the
   % smoke script. This file tests eventtau, globalfit, cloudphi, fitphi,
   % and dndtuncertainty on the example data, and gpfitb, fitphidist, and
   % aQbString on synthetic inputs. The chain runs once on the shipped
   % example data in setupOnce; the constants are the Kuparuk basin values
   % the demos use.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Run the example-data chain once; event fitting is the slow part.
   [T, Q, R] = baseflow.loadExampleData();
   Events = baseflow.getevents(T, Q, R, baseflow.setopts('getevents'));
   [Fits, FitsTable] = baseflow.fitevents(Events, ...
      baseflow.setopts('fitevents'));
   testCase.TestData.T = T;
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
   % example data. The default 'pointcloud' phi method passes plotfits to
   % cloudphi, so a fit with plotfits false opens no figure. The teardown
   % closes any figure a failed run leaves open.
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
   newfigs_expected = 0;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)
end

function test_cloudphiPlotfit(testCase)
   % cloudphi draws one point-cloud figure by default and no figure with
   % plotfit false. The plotfit flag controls only the figure, so both
   % calls return the same phi. The late-time exponent is the linear
   % (b = 1) value, which selects the PK62 / BS03 solution pair.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   A = testCase.TestData.A;
   D = testCase.TestData.D;
   L = testCase.TestData.L;
   blate = testCase.TestData.b2_linear;
   [~, q, dqdt] = baseflow.eventtau(testCase.TestData.FitsTable, ...
      testCase.TestData.Events, testCase.TestData.Fits, 'usefits', false);

   % The default call draws one figure.
   phi_expected = baseflow.cloudphi(q, dqdt, blate, A, D, L, 'envelope');
   newfigs_returned = numel(findall(0, 'Type', 'figure')) ...
      - numel(figsbefore);
   newfigs_expected = 1;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)

   % The plotfit false call draws no figure and returns the same phi.
   figsplotted = findall(0, 'Type', 'figure');
   phi_returned = baseflow.cloudphi(q, dqdt, blate, A, D, L, 'envelope', ...
      'plotfit', false);
   newfigs_returned = numel(findall(0, 'Type', 'figure')) ...
      - numel(figsplotted);
   newfigs_expected = 0;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)
   testCase.verifyEqual(phi_returned, phi_expected)
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

function test_gpfitbLabelDrawsAnArrow(testCase)
   % gpfitb labels tau0 and the mean tau with an arrow, which drawarrow
   % draws as a tagged head patch and a tagged shaft line. The exponent
   % is above the tau pole at alpha 2, so the mean tau is positive and
   % both labels have a point on the axes to name.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   nsamples = 5000;
   pdfexponent = 2.5;
   xmin = 1;
   nlabels_expected = 2;

   u = ((1:nsamples)' - 0.5)/nsamples;
   x = (1 - u).^(-1/(pdfexponent - 1));
   baseflow.gpfitb(x, 'xmin', xmin, 'plotfit', true, 'bootfit', false, ...
      'labelplot', true);

   ax = gca;
   testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowhead'), ...
      nlabels_expected)
   testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowshaft'), ...
      nlabels_expected)
end

function test_plplotbLabelDrawsAnArrow(testCase)
   % plplotb labels tau0 and the mean tau with the same arrow.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   nsamples = 5000;
   pdfexponent = 2.5;
   xmin = 1;
   nlabels_expected = 2;

   u = ((1:nsamples)' - 0.5)/nsamples;
   x = (1 - u).^(-1/(pdfexponent - 1));
   baseflow.plplotb(x, xmin, pdfexponent, 'labelplot', true);

   ax = gca;
   testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowhead'), ...
      nlabels_expected)
   testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowshaft'), ...
      nlabels_expected)
end

function test_fitphidistLabelDrawsAnArrow(testCase)
   % The 'cdf' plot type labels the mean of phi with one arrow, which
   % points left at the mean from a tail to its right.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   nsamples = 500;
   phimean = 0.05;
   phistd = 0.01;
   phifloor = 1e-3;
   phiceil = 0.2;
   nlabels_expected = 1;
   phid = min(max(phimean + phistd*randn(nsamples, 1), phifloor), phiceil);

   baseflow.fitphidist(phid, 'PD', 'cdf', true);

   ax = gca;
   testCase.verifyNumElements(findall(ax, 'Tag', 'refarrowhead'), ...
      nlabels_expected)
   hhead = findall(ax, 'Tag', 'refarrowhead');
   hshaft = findall(ax, 'Tag', 'refarrowshaft');
   testCase.verifyLessThan(min(get(hhead, 'XData')), ...
      min(get(hshaft, 'XData')))
end

function test_fitphidistNominal(testCase)
   % fitphidist recovers the mean of a synthetic phi sample, and with
   % showfit false it leaves no figure open. The teardown closes any
   % figure a failed run leaves open.
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

   % The 'pdf' type draws no figure and returns an empty struct for h.
   [~, h_returned] = baseflow.fitphidist(phid, 'PD', 'pdf', showfit);
   h_expected = struct();
   testCase.verifyEqual(h_returned, h_expected)
   newfigs_returned = numel(findall(0, 'Type', 'figure')) - numel(figsbefore);
   newfigs_expected = 0;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)
end

function test_dndtuncertaintyAlpha(testCase)
   % dndtuncertainty multiplies its combined standard uncertainty by the
   % coverage factor norminv(1-alpha/2), so the result for alpha 0.32
   % equals the result for alpha 0.05 times the ratio of those factors. A
   % result that ignores alpha keeps a ratio of 1. The same random seed
   % gives both calls the same phi bootstrap. The teardown closes any
   % figure a failed run leaves open.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   gopts = baseflow.setopts('globalfit', ...
      'drainagearea', testCase.TestData.A, ...
      'drainagedensity', testCase.TestData.drainagedensity, ...
      'streamlength', testCase.TestData.L, ...
      'aquiferdepth', testCase.TestData.D, ...
      'isflat', true, 'plotfits', false, 'bootfit', false);
   GlobalFit = baseflow.globalfit(testCase.TestData.FitsTable, ...
      testCase.TestData.Events, testCase.TestData.Fits, gopts);

   % One annual baseflow value per year of the example record.
   T = testCase.TestData.T;
   nyears = numel(unique(year(T)));
   trendslope = 0.01;
   oscillation = 5;
   years = transpose(1:nyears);
   Qb = trendslope*years + oscillation*sin(3*years);
   alpha_default = 0.05;
   alpha_onesigma = 0.32;
   seed = 1;
   tol = 0.01;

   rng(seed)
   sig_default = baseflow.dndtuncertainty(T, Qb, ...
      testCase.TestData.FitsTable, testCase.TestData.Fits, GlobalFit, ...
      gopts, alpha_default);
   rng(seed)
   sig_onesigma = baseflow.dndtuncertainty(T, Qb, ...
      testCase.TestData.FitsTable, testCase.TestData.Fits, GlobalFit, ...
      gopts, alpha_onesigma);

   ratio_expected = norminv(1 - alpha_onesigma/2) ...
      / norminv(1 - alpha_default/2);
   ratio_returned = sig_onesigma / sig_default;
   testCase.verifyEqual(ratio_returned, ratio_expected, 'RelTol', tol)

   % The dq/dt column is constant, so the correlation matrix holds it
   % uncorrelated with the event variables and the result stays finite.
   testCase.verifyTrue(isfinite(sig_default))

   % dndtuncertainty leaves no figure open.
   newfigs_returned = numel(findall(0, 'Type', 'figure')) - numel(figsbefore);
   newfigs_expected = 0;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)
end

function test_dndtuncertaintyInvalidAlpha(testCase)
   % dndtuncertainty rejects an alpha outside (0, 1) before it uses the
   % other inputs, so empty placeholders suffice.
   alpha_invalid = 1.5;
   testCase.verifyError(@() baseflow.dndtuncertainty([], [], [], [], ...
      [], [], alpha_invalid), 'baseflow:dndtuncertainty:invalidAlpha')
end

function test_fitphidistProbplot(testCase)
   % fitphidist draws the 'probplot' figure with the fitted beta
   % distribution line when showfit is true, and leaves no figure when
   % showfit is false. The teardown closes the figure.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   nsamples = 200;
   phimean = 0.05;
   phistd = 0.01;
   phifloor = 1e-3;
   phiceil = 0.2;
   phid = min(max(phimean + phistd*randn(nsamples, 1), phifloor), phiceil);
   [~, returned] = baseflow.fitphidist(phid, 'PD', 'probplot', true);
   testCase.verifyTrue(isgraphics(returned.fit))
   closenewfigs(figsbefore)
   baseflow.fitphidist(phid, 'PD', 'probplot', false);
   newfigs_returned = numel(findall(0, 'Type', 'figure')) - numel(figsbefore);
   newfigs_expected = 0;
   testCase.verifyEqual(newfigs_returned, newfigs_expected)
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
   % fitphi warns before it falls back, and this test asks for the pair
   % that triggers the fallback, so the warning is expected output rather
   % than a problem to print.
   testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
      'baseflow:fitphi:incompatibleLateTimeSolution'));
   a1 = testCase.TestData.a1;
   a2 = testCase.TestData.a2;
   b2_linear = testCase.TestData.b2_linear;
   expected = 'baseflow:fitphi:unsupportedSolution';
   testCase.verifyError(@() baseflow.fitphi(a1, a2, b2_linear, ...
      testCase.TestData.A, testCase.TestData.D, testCase.TestData.L), ...
      expected)
end
