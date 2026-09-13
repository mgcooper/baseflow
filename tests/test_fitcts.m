classdef test_fitcts < matlab.unittest.TestCase
   %TEST_FITCTS Test the constant-time-step dq/dt method.
   %
   % fitcts is private, so the tests reach it with baseflow.privatefunction.
   % The tests compare every stencil with the analytic derivative of an
   % exponential recession, where dq/dt = -q/tau exactly. Higher-order
   % stencils get smaller tolerances. The fourth-order C4 tolerance also
   % detects a C4 stencil that cancels its Q_{i+2} term or omits Q_{i-2}.

   properties (TestParameter)
      % Each case holds a stencil name and its relative tolerance. B1 and
      % F1 are first-order accurate: a few percent at dt/tau = 0.05. B2,
      % F2, and C2 are second-order accurate. C4 is fourth-order accurate.
      % A C4 stencil that cancels its Q_{i+2} term or omits Q_{i-2} fails
      % this tolerance by orders of magnitude.
      stencil = struct( ...
         'B1', {{'B1', 0.05}}, ...
         'F1', {{'F1', 0.05}}, ...
         'B2', {{'B2', 0.005}}, ...
         'F2', {{'F2', 0.005}}, ...
         'C2', {{'C2', 0.005}}, ...
         'C4', {{'C4', 1e-4}})

      % Each case holds a stencil name and the formula for its tqmid
      % midpoint times: backward stencils post at (T(i)+T(i-1))/2, forward
      % stencils at (T(i)+T(i+1))/2, and centered stencils at
      % (T(i+1)+T(i-1))/2. Edge samples are nan.
      midpoint = struct( ...
         'B1', {{'B1', @(T) [nan; (T(2:end) + T(1:end-1)) / 2]}}, ...
         'B2', {{'B2', @(T) [nan; (T(2:end) + T(1:end-1)) / 2]}}, ...
         'F1', {{'F1', @(T) [(T(1:end-1) + T(2:end)) / 2; nan]}}, ...
         'F2', {{'F2', @(T) [(T(1:end-1) + T(2:end)) / 2; nan]}}, ...
         'C2', {{'C2', @(T) [nan; (T(3:end) + T(1:end-2)) / 2; nan]}}, ...
         'C4', {{'C4', @(T) [nan; (T(3:end) + T(1:end-2)) / 2; nan]}})
   end

   properties
      % The private fitcts function handle, the recession signal, and its
      % analytic derivative.
      fitcts
      daystep
      T
      Q
      R
      dqdt_analytic
   end

   methods (TestClassSetup)
      function makerecession(testCase)
         % Daily exponential recession: q = q0 exp(-t/tau), dq/dt = -q/tau.
         testCase.fitcts = baseflow.privatefunction('fitcts');
         tau = 20;
         q0 = 100;
         testCase.daystep = 1;
         ndays = 60;
         testCase.T = transpose(0:testCase.daystep:ndays);
         testCase.Q = q0*exp(-testCase.T/tau);
         testCase.R = zeros(size(testCase.Q));
         testCase.dqdt_analytic = -testCase.Q/tau;
      end
   end

   methods (Test)
      function test_stencilAccuracy(testCase, stencil)
         % The stencil derivative matches the analytic one at every interior
         % sample within the relative tolerance reltol.
         [method, reltol] = stencil{:};
         [~, dqdt] = testCase.fitcts(testCase.T, testCase.Q, testCase.R, ...
            method);
         expected = testCase.dqdt_analytic;

         % Require most samples to be interior so the check is not vacuous.
         mininterior = 50;
         keep = ~isnan(dqdt);
         testCase.assertGreaterThan(nnz(keep), mininterior)

         returned = max(abs(dqdt(keep) - expected(keep)) ...
            ./ abs(expected(keep)));
         testCase.verifyLessThan(returned, reltol, sprintf( ...
            'stencil %s relative error %.2g exceeds %.2g', method, ...
            returned, reltol))
      end

      function test_defaultsAndAlignment(testCase)
         % With no method input, fitcts uses B1. tq and rq post on the input
         % vectors, and dt is the constant sample step.
         [q_returned, dqdt_returned, dt_returned, tq_returned, ...
            rq_returned] = testCase.fitcts(testCase.T, testCase.Q, testCase.R);
         [q_expected, dqdt_expected] = testCase.fitcts(testCase.T, ...
            testCase.Q, testCase.R, 'B1');
         dt_expected = testCase.daystep * ones(size(testCase.T));
         tq_expected = testCase.T;
         rq_expected = testCase.R;

         testCase.verifyEqual(q_returned, q_expected)
         testCase.verifyEqual(dqdt_returned, dqdt_expected)
         testCase.verifyEqual(tq_returned, tq_expected)
         testCase.verifyEqual(rq_returned, rq_expected)
         testCase.verifyEqual(dt_returned, dt_expected)
      end

      function test_midpointTimes(testCase, midpoint)
         % tqmid returns the stencil midpoint time of each sample.
         [method, formula] = midpoint{:};
         expected = formula(testCase.T);
         [~, ~, ~, ~, ~, ~, returned] = testCase.fitcts(testCase.T, ...
            testCase.Q, testCase.R, method);
         testCase.verifyEqual(returned, expected)
      end

      function test_nonuniformTimeErrors(testCase)
         % A time vector with a gap raises the uniformity error: one shared
         % dt would be wrong for every stencil.
         T_gapped = [0; 1; 3];
         Q_gapped = [3; 2; 1];
         R_gapped = zeros(size(T_gapped));
         expected = 'baseflow:fitcts:nonuniformTime';
         testCase.verifyError(@() testCase.fitcts(T_gapped, Q_gapped, ...
            R_gapped), expected)
      end

      function test_unknownMethodErrors(testCase)
         % An unrecognized stencil name raises the validatestring error.
         expected = 'MATLAB:fitcts:unrecognizedStringChoice';
         testCase.verifyError(@() testCase.fitcts(testCase.T, testCase.Q, ...
            testCase.R, 'X9'), expected)
      end

      function test_throughGetdqdt(testCase)
         % The public getdqdt CTS method returns finite derivatives on the test
         % signal.
         [q_returned, dqdt_returned] = baseflow.getdqdt(testCase.T, ...
            testCase.Q, testCase.R, 'CTS', 'ctsmethod', 'C2');
         testCase.verifyTrue(any(~isnan(q_returned)))
         testCase.verifyTrue(any(~isnan(dqdt_returned)))
      end
   end
end
