function tests = test_fitphidist
   %TEST_FITPHIDIST Test the phi distribution fit of baseflow.fitphidist.
   %
   % fitphidist fits a beta distribution to a sample of phi and returns its
   % mean or mode, with optional cdf, pdf, and probability plots.
   tests = functiontests(localfunctions);
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

function test_phiOutsideUnitIntervalIsLeftOut(testCase)
   % A phi outside [0, 1] is not a porosity, and the beta distribution
   % cannot hold it. fitphidist leaves it out of the fit with a warning. So
   % the mean equals the mean of the beta fit to the values inside [0, 1].
   phi_inside = [0.02; 0.03; 0.04; 0.05; 0.06; 0.08];
   phi_outside = [1.7; -0.2];
   params = betafit(phi_inside);
   expected = betastat(params(1), params(2));

   returned = testCase.verifyWarning(@() baseflow.fitphidist( ...
      [phi_inside; phi_outside], 'mean'), ...
      'baseflow:fitphidist:phiOutsideUnitInterval');

   testCase.verifyEqual(returned, expected)
end
