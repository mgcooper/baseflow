function tests = test_cloudphi
   %TEST_CLOUDPHI Test the plotfit and userab options of baseflow.cloudphi.
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

function test_userabSetsTheLateTimeLine(testCase)
   % userab sets the late-time line, and the early-time line still comes
   % from the point cloud. Every quantile of a cloud of one repeated point
   % (q, -dq/dt) = (2, 1/2) is that point. So the early-time line of slope
   % 3 has a1 = (1/2)/2^3. With the late-time b = 3/2 of userab, the PK62
   % and BS04 solutions of Troch et al. (1993) give phi =
   % 1.133^(1/3)*4.804^(2/3)/(D*A*a1^(1/3)*a2^(2/3)). blate = 1 would select
   % the BS03 solution, so the result also shows blate does not enter phi.
   A = 8.6545e9;
   D = 0.5;
   L = A*0.8/1000;
   blate = 1;
   npoints = 10;
   q = 2*ones(npoints, 1);
   dqdt = -0.5*ones(npoints, 1);
   a1 = 0.5/2^3;
   userab = [1e-11 3/2];
   phi_expected = 1.133^(1/3)*4.804^(2/3) ...
      /(D*A*a1^(1/3)*userab(1)^(2/3));
   tol = 1e-12;

   [phi_returned, a_returned] = baseflow.cloudphi(q, dqdt, blate, A, D, L, ...
      'envelope', 'userab', userab, 'plotfit', false);

   testCase.verifyEqual(phi_returned, phi_expected, 'RelTol', tol)
   testCase.verifyEqual(a_returned, userab(1))
end
