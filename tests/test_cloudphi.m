function tests = test_cloudphi
   %TEST_CLOUDPHI Test the plotfit option of baseflow.cloudphi.
   %
   % The inputs are the Kuparuk basin constants of the demos and a
   % synthetic point cloud from baseflow.generateTestData.
   tests = functiontests(localfunctions);
end

function test_cloudphiPlotfit(testCase)
   % cloudphi draws one point-cloud figure by default and no figure with
   % plotfit false. The plotfit flag controls only the figure, so both
   % calls return the same phi. The late-time exponent is the linear
   % (b = 1) value, which selects the PK62 / BS03 solution pair.
   figsbefore = findall(0, 'Type', 'figure');
   testCase.addTeardown(@() closenewfigs(figsbefore));
   A = 8.6545e9;
   D = 0.5;
   L = A*0.8/1000;
   blate = 1;
   [~, q, dqdt] = baseflow.generateTestData(1e-2, 1.5, 100);

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
