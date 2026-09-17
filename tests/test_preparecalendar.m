classdef test_preparecalendar < matlab.unittest.TestCase
   %TEST_PREPARECALENDAR Test the private preparecalendar helper.
   %
   % preparecalendar is private, so the tests reach it with
   % baseflow.privatefunction. preparecalendar finds timestep only for a
   % regular calendar with leap days. The cases check that every other
   % calendar returns an empty timestep. A calendar without leap days keeps
   % its samples, and an irregular calendar loses its leap days.

   properties (TestParameter)
      % Each case holds a time vector with no leap days.
      calendar = struct( ...
         'regularLeapFree', {transpose(datetime(2001, 1, 1:365))}, ...
         'irregular', {transpose(datetime(2001, 1, [1 2 4 5]))})
   end

   properties
      % The private preparecalendar function handle.
      preparecalendar
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.preparecalendar = baseflow.privatefunction( ...
            'preparecalendar');
      end
   end

   methods (Test)
      function test_timestepEmpty(testCase, calendar)
         % A calendar without leap days returns an empty timestep, the
         % input time vector, and numyears = numel(T)/365.
         T = calendar;
         Q = transpose(1:numel(T));
         R = zeros(size(Q));
         T_expected = T;
         numyears_expected = numel(T) / 365;

         [T_returned, ~, ~, numyears_returned, timestep_returned] = ...
            testCase.preparecalendar(T, Q, R);

         testCase.verifyEmpty(timestep_returned)
         testCase.verifyEqual(T_returned, T_expected)
         testCase.verifyEqual(numyears_returned, numyears_expected)
      end

      function test_irregularLeapCalendar(testCase)
         % An irregular calendar with a leap day returns an empty timestep
         % and drops the leap day from T, Q, and R. The function warns
         % twice with no warning identifier, so the test turns warnings off.
         T = transpose(datetime(2004, 2, [27 28 29]));
         T = [T; datetime(2004, 3, 2)];
         Q = transpose(1:numel(T));
         R = 10 * Q;
         keep = [1; 2; 4];
         T_expected = T(keep);
         Q_expected = Q(keep);
         R_expected = R(keep);

         warnstate = warning('off', 'all');
         restorewarnings = onCleanup(@() warning(warnstate));
         [T_returned, Q_returned, R_returned, ~, timestep_returned] = ...
            testCase.preparecalendar(T, Q, R);
         clear restorewarnings

         testCase.verifyEmpty(timestep_returned)
         testCase.verifyEqual(T_returned, T_expected)
         testCase.verifyEqual(Q_returned, Q_expected)
         testCase.verifyEqual(R_returned, R_expected)
      end
   end
end
