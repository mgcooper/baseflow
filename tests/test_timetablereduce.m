classdef test_timetablereduce < matlab.unittest.TestCase
   %TEST_TIMETABLEREDUCE Test timetablereduce and renametimetabletimevar.
   %
   % Both functions are private, so the tests reach them with
   % baseflow.privatefunction. timetablereduce calls renametimetabletimevar
   % before it reads the row times, so inputs with a time dimension named
   % 'Date' test the rename path. Expected statistics are hand-computed
   % from the data: the mean and sample standard deviation of the non-NaN
   % values, SE = sigma/sqrt(N), and CIL and CIH = mu -/+ PM. Every sample
   % has N < 5, so stderror sets PM = sf*SE, with sf = 1 for alpha = 0.32
   % and sf = 2 for alpha = 0.05.
   %
   % Three timetablereduce paths have no test because they error for the
   % inputs that reach them: the property-copy block, for an input with
   % VariableUnits or VariableContinuity; a dim other than 1 or 2, which
   % leaves CI unassigned; and one column with keeptime = false, which
   % errors in setnan when the column has two or more valid values. A test
   % here would assert the defect.

   properties (TestParameter)
      % Row reductions of the shared data. Each case holds the optional
      % timetablereduce arguments and the scale factor sf. An explicit
      % dim = 2 matches the default. alpha = 0.05 doubles the error margin
      % for N < 5.
      rowoptions = struct( ...
         'default', {{{}, 1}}, ...
         'dim2Alpha', {{{2, 'alpha', 0.05}, 2}})
   end

   properties
      % The private function handles and the shared data.
      timetablereduce
      rename
      Date
      TT
   end

   methods (TestClassSetup)
      function makedata(testCase)
         % Store the private function handles and shared data once. The
         % data use a time dimension named 'Date' so every call renames it.
         testCase.timetablereduce = ...
            baseflow.privatefunction('timetablereduce');
         testCase.rename = ...
            baseflow.privatefunction('renametimetabletimevar');

         % Four times and three sites: row statistics use N = [3; 3; 2; 3].
         testCase.Date = datetime(2020, 1, 1:4)';
         A = [1, 2, 3; 2, 4, 6; NaN, 1, 3; 5, 5, 5];
         testCase.TT = array2timetable(A, 'RowTimes', testCase.Date, ...
            'VariableNames', {'s1', 's2', 's3'});
         testCase.TT.Properties.DimensionNames{1} = 'Date';
      end
   end

   methods (Test)
      function test_renameHelperRenamesTimeDimension(testCase)
         % A timetable or table whose first dimension name is not 'Time'
         % gets the name 'Time'; the row times and variables stay the same.
         T = table([1; 2], 'VariableNames', {'x'});
         dims_expected = {'Time', 'Variables'};
         rowtimes_expected = testCase.Date;
         vars_expected = {'s1', 's2', 's3'};

         returned = testCase.rename(testCase.TT);
         testCase.verifyEqual(returned.Properties.DimensionNames, ...
            dims_expected)
         testCase.verifyEqual(returned.Properties.RowTimes, ...
            rowtimes_expected)
         testCase.verifyEqual(returned.Properties.VariableNames, ...
            vars_expected)

         table_returned = testCase.rename(T);
         testCase.verifyEqual(table_returned.Properties.DimensionNames, ...
            dims_expected)
      end

      function test_renameHelperKeepsTimeDimension(testCase)
         % renametimetabletimevar returns a timetable unchanged when its first
         % dimension name is 'Time'.
         Time = testCase.Date;
         x = [1; 2; 3; 4];
         TTtime = timetable(Time, x);
         expected = TTtime;

         returned = testCase.rename(TTtime);
         testCase.verifyEqual(returned, expected)
      end

      function test_reduceRows(testCase, rowoptions)
         % dim = 2 (the default) reduces across sites at each time. The
         % output timetable uses 'Time' and keeps the input row times.
         [args, sf] = rowoptions{:};
         dims_expected = {'Time', 'Variables'};
         rowtimes_expected = testCase.Date;
         vars_expected = {'mu', 'sigma', 'SE', 'CIL', 'CIH', 'PM'};
         mu_expected = [2; 4; 2; 5];
         sigma_expected = [1; 2; sqrt(2); 0];
         N_expected = [3; 3; 2; 3];

         returned = testCase.verifyWarningFree( ...
            @() testCase.timetablereduce(testCase.TT, args{:}));

         testCase.verifyEqual(returned.Properties.DimensionNames, ...
            dims_expected)
         testCase.verifyEqual(returned.Properties.RowTimes, ...
            rowtimes_expected)
         testCase.verifyEqual(returned.Properties.VariableNames, ...
            vars_expected)
         verifystats(testCase, returned, mu_expected, sigma_expected, ...
            N_expected, sf)
      end

      function test_reduceColumns(testCase)
         % dim = 1 reduces each variable over time and returns a table with
         % one row per input variable. Four variables over three times keep
         % the transposed array taller than wide, so stderror does not warn.
         dates = datetime(2020, 1, 1:3)';
         B = [1, 2, 3, 4; 2, 4, 6, 8; 3, 3, 3, NaN];
         varnames = {'a', 'b', 'c', 'd'};
         TB = array2timetable(B, 'RowTimes', dates, ...
            'VariableNames', varnames);
         TB.Properties.DimensionNames{1} = 'Date';
         rownames_expected = varnames';
         mu_expected = [2; 3; 4; 6];
         sigma_expected = [1; 1; sqrt(3); sqrt(8)];
         N_expected = [3; 3; 3; 2];
         sf = 1;

         returned = testCase.verifyWarningFree( ...
            @() testCase.timetablereduce(TB, 1));

         testCase.verifyClass(returned, 'table')
         testCase.verifyEqual(returned.Properties.RowNames, ...
            rownames_expected)
         verifystats(testCase, returned, mu_expected, sigma_expected, ...
            N_expected, sf)
      end

      function test_singleColumnKeepTime(testCase)
         % One column with keeptime = true returns the data as 'mu' and
         % fills the other statistics with NaN, so table headers stay
         % consistent.
         T1 = testCase.TT(:, 1);
         dims_expected = {'Time', 'Variables'};
         vars_expected = {'mu', 'SE', 'CI', 'PM', 'sigma'};
         mu_expected = [1; 2; NaN; 5];
         nan_expected = NaN(4, 1);

         returned = testCase.timetablereduce(T1, 'keeptime', true);

         testCase.verifyEqual(returned.Properties.DimensionNames, ...
            dims_expected)
         testCase.verifyEqual(returned.Properties.VariableNames, ...
            vars_expected)
         testCase.verifyEqual(returned.mu, mu_expected)
         testCase.verifyEqual(returned.SE, nan_expected)
         testCase.verifyEqual(returned.CI, nan_expected)
         testCase.verifyEqual(returned.PM, nan_expected)
         testCase.verifyEqual(returned.sigma, nan_expected)
      end

      function test_inputValidation(testCase)
         % The input parser rejects a non-timetable input and a non-logical
         % keeptime value.
         errid = 'MATLAB:InputParser:ArgumentFailedValidation';

         testCase.verifyError(@() testCase.timetablereduce([1, 2; 3, 4]), ...
            errid)
         testCase.verifyError(@() testCase.timetablereduce(testCase.TT, ...
            'keeptime', 1), errid)
      end
   end
end

function verifystats(testCase, NewData, mu_expected, sigma_expected, ...
      N_expected, sf)
   % Shared check: the reduced statistics match the hand-computed mean,
   % standard deviation, and sample count with scale factor sf. The
   % tolerance absorbs floating-point rounding only.
   tol = 1e-12;
   SE_expected = sigma_expected./sqrt(N_expected);
   PM_expected = sf*SE_expected;
   CIL_expected = mu_expected - PM_expected;
   CIH_expected = mu_expected + PM_expected;

   testCase.verifyEqual(NewData.mu, mu_expected, 'AbsTol', tol)
   testCase.verifyEqual(NewData.sigma, sigma_expected, 'AbsTol', tol)
   testCase.verifyEqual(NewData.SE, SE_expected, 'AbsTol', tol)
   testCase.verifyEqual(NewData.PM, PM_expected, 'AbsTol', tol)
   testCase.verifyEqual(NewData.CIL, CIL_expected, 'AbsTol', tol)
   testCase.verifyEqual(NewData.CIH, CIH_expected, 'AbsTol', tol)
end
