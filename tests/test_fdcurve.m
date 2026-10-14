function tests = test_fdcurve
   %TEST_FDCURVE Test the reference points of baseflow.fdcurve.
   %
   % fdcurve ranks the flows from largest to smallest and returns the
   % position f = 1 - M/(N+1), where M counts the flows at or above a
   % point and N counts the flows that are not missing.
   tests = functiontests(localfunctions);
end

function test_referencePointPositions(testCase)
   % Three flows and one missing value give N = 3 and the positions
   % [0.75 0.5 0.25] for 0.3, 0.2, and 0.1. Each point gets its own value:
   % a nan point and a point above every flow have no position.
   flow = [0.1; 0.2; 0.3; nan];
   refpoints = [nan 0.2 0.35];
   fref_expected = [nan 0.5 nan];
   f_expected = [0.75 0.5 0.25];
   tolerance = 1e-12;

   fdc = baseflow.fdcurve(flow, 'refpoints', refpoints, 'plotfit', false);

   testCase.verifyEqual(fdc.fref, fref_expected, 'AbsTol', tolerance)
   testCase.verifyEqual(fdc.f, f_expected, 'AbsTol', tolerance)
end
