classdef test_loadflow < matlab.unittest.TestCase
   %TEST_LOADFLOW Test the loadflow unit conversions.
   %
   % loadflow reads flow_prepped.mat from BASEFLOW_DATA_PATH. The tests
   % write a one-station file to a temporary folder, point the environment
   % variable at it, and compare each converted flow with the unit formula.

   properties (TestParameter)
      % Each case holds a units option and the factor that converts m3/s
      % to that unit for a basin of 2 km2 (2e6 m2) with 86400 s per day.
      units = struct( ...
         'm3_per_day', {{'m3/d', 86400}}, ...
         'mm_per_day', {{'mm/d', 86400 / 2e6 * 1000}}, ...
         'km3_per_year', {{'km3/y', 86400 * 365.25 / 1e9}})
   end

   properties
      % Flow in m3/s that the temporary data file holds.
      Q_m3s = [1; 2; 3; 4]
   end

   methods (TestClassSetup)
      function writedatafile(testCase)
         % Write the data file and set BASEFLOW_DATA_PATH for every test.
         import matlab.unittest.fixtures.TemporaryFolderFixture
         import matlab.unittest.fixtures.EnvironmentVariableFixture

         folder = testCase.applyFixture(TemporaryFolderFixture).Folder;
         mkdir(fullfile(folder, 'flow'))
         Flow.Q = testCase.Q_m3s;
         Flow.T = transpose(datetime(2001, 1, 1:4));
         Flow.Meta = table({'testbasin'}, 2, ...
            'VariableNames', {'name', 'darea'});
         save(fullfile(folder, 'flow', 'flow_prepped.mat'), 'Flow')
         testCase.applyFixture(EnvironmentVariableFixture( ...
            'BASEFLOW_DATA_PATH', folder));
      end
   end

   methods (Test)
      function test_convertsUnits(testCase, units)
         % The converted flow equals the m3/s flow times the unit factor,
         % and the m3/s flow stays in the Qm3s variable.
         [unitname, factor] = units{:};
         Q_expected = testCase.Q_m3s * factor;
         tolerance = 1e-12;

         Flow = baseflow.loadflow('testbasin', 'units', unitname);

         testCase.verifyEqual(Flow.Q, Q_expected, 'RelTol', tolerance)
         testCase.verifyEqual(Flow.Qm3s, testCase.Q_m3s)
      end
   end
end
