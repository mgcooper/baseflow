classdef test_plotaquifertrend < matlab.unittest.TestCase
   %TEST_PLOTAQUIFERTREND Test the plotaquifertrend branch handles.
   %
   % plotaquifertrend selects the streamflow, CALM, or GRACE branch from the
   % optional inputs. Each test checks that the selected branch runs and
   % returns one trendplot handle field for each plotted series.

   properties (TestParameter)
      % Number of optional inputs after sigDb. Zero selects the streamflow
      % branch, Dc and sigDc select the CALM branch, and Dg also selects the
      % GRACE branch.
      noptional = struct('flow', 0, 'calm', 2, 'grace', 3)
      % Trendplot handle fields that each branch returns, in order.
      fields_expected = struct( ...
         'flow', {{'trendplot'}}, ...
         'calm', {{'trendplot1'; 'trendplot2'}}, ...
         'grace', {{'trendplot1'; 'trendplot2'; 'trendplot3'}})
   end

   properties
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Test, ParameterCombination = 'sequential')
      function test_branchHandles(testCase, noptional, fields_expected)
         % The branch that the optional inputs select returns its
         % trendplot handles. The series share one noisy linear trend with
         % unit uncertainty because the test checks handles, not fits.
         t = transpose(2002:2020);
         D = transpose(1:numel(t)) + sin(t);
         sigD = ones(size(t));
         optional = {D, sigD, D};

         returned = baseflow.plotaquifertrend(t, D, sigD, ...
            optional{1:noptional});

         testCase.verifyEqual(fieldnames(returned.baseflow), fields_expected)
      end
   end
end
