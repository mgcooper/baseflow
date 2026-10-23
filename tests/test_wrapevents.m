classdef test_wrapevents < matlab.unittest.TestCase
   %TEST_WRAPEVENTS Check annual calendar and data alignment.

   properties (TestParameter)
      calendar = struct( ...
         'leapYear', {[2000 2000]}, ...
         'nonLeapYear', {[2001 2001]}, ...
         'twoYears', {[2000 2001]})
      timeType = {'datetime', 'datenum'}
   end

   methods (Test)

      function test_leapDayAlignment(testCase, calendar, timeType)
         % Distinct row values expose calendar/data shifts after removal.
         T = transpose(datetime(calendar(1), 1, 1): ...
            datetime(calendar(2), 12, 31));
         row = transpose(1:numel(T));
         Q = 2 + sin(row / 10);
         R = row / 1000;

         % Only February 29, 2000 is excluded from these calendars.
         keep = T ~= datetime(2000, 2, 29);
         T_expected = datenum(T(keep));
         Q_expected = Q(keep);
         R_expected = R(keep);

         % Both public time representations must select the same rows.
         if strcmp(timeType, 'datenum')
            T = datenum(T);
         end

         % Rain carries row identities; it must not reject flow events.
         returned = baseflow.wrapevents(T, Q, R, ...
            'rmrain', false, 'pickevents', false, 'plotevents', false);

         testCase.verifyEqual(returned.inputTime, T_expected)
         testCase.verifyEqual(returned.inputFlow, Q_expected)
         testCase.verifyEqual(returned.inputRain, R_expected)
      end

   end
end
