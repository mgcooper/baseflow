function tests = test_plplotb
   %TEST_PLPLOTB Test the tau0 and mean-tau labels of baseflow.plplotb.
   %
   % The mean of a Pareto tail diverges at or below the tau pole at
   % alpha = 2, so the label has no point on the axes to name. Above the
   % pole, the label names tau0 and the mean tau.
   tests = functiontests(localfunctions);
end

function test_labelOmitsDivergentMean(testCase)
   % With alpha = 1.5, plplotb labels tau0 only. No text names a mean tau,
   % and drawarrow does not warn about a point off the log axis. The pole
   % warning of expectedtau is expected here.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
      'baseflow:expectedtau:tauPole'));
   nsamples = 5000;
   xmin = 10;
   belowpolealpha = 1.5;
   narrows_expected = 1;

   % Inverse-CDF sample at midpoint probabilities: the ccdf exponent is
   % the pdf exponent minus 1.
   u = ((1:nsamples)' - 0.5)/nsamples;
   x = xmin * (1 - u).^(-1/(belowpolealpha - 1));

   h = testCase.verifyWarningFree(@() baseflow.plplotb(x, xmin, ...
      belowpolealpha, 'labelplot', true));

   testCase.verifyNumElements(findall(h.ax, 'Tag', 'refarrowhead'), ...
      narrows_expected)
   labels_returned = get(findall(h.ax, 'Type', 'text'), 'String');
   testCase.verifyFalse(any(contains(labels_returned, 'langle')))
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
