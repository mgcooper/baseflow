classdef test_snaploglims < matlab.unittest.TestCase
   %TEST_SNAPLOGLIMS Test the log-axis limit policy.
   %
   % snaploglims moves an axis limit out to its decade when that decade is
   % nearer than the tolerance the policy sets. A limit that stays where it
   % is takes the padding the caller passes. 'snap' snaps a limit within a
   % quarter decade, 'decades' snaps every limit, and 'none' snaps none.

   properties (TestParameter)
      % The three policies snaploglims accepts.
      axislimits = struct('snap', 'snap', 'decades', 'decades', ...
         'none', 'none')

      % Limits that no policy can place on a log axis.
      badlims = struct('zerolow', [0 100], 'negativelow', [-1 100], ...
         'infinitehigh', [1 Inf], 'nanhigh', [1 NaN])
   end

   properties (Constant)
      % Multipliers for a limit that does not snap. These are the values
      % pointcloudplot passes for its x axis.
      pad = [0.9 1.1]

      % Rounding error allowed between a computed and an expected limit.
      tolerance = 1e-12
   end

   properties
      % Handle to the private function under test.
      snaploglims
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.snaploglims = baseflow.privatefunction('snaploglims');
      end
   end

   methods (Test)
      function test_limitOnItsDecadeKeepsItsValue(testCase, axislimits)
         % A limit already on a decade has no gap to close, so snap and
         % decades leave it. none snaps nothing, so it takes the padding.
         lims = [100 10000];
         lims_expected = lims;
         if strcmp(axislimits, 'none')
            lims_expected = lims .* testCase.pad;
         end

         lims_returned = testCase.snaploglims(lims, testCase.pad, axislimits);

         testCase.verifyEqual(lims_returned, lims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_nearLimitSnapsToItsDecade(testCase)
         % 13762 sits 0.139 decades above 1e4, inside the quarter-decade
         % tolerance. 1.90119e6 sits 0.721 decades below 1e7, outside it,
         % so the high limit takes the padding.
         lims = [13762 1.90119e6];
         lims_expected = [1e4 1.90119e6 * testCase.pad(2)];

         lims_returned = testCase.snaploglims(lims, testCase.pad, 'snap');

         testCase.verifyEqual(lims_returned, lims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_farLimitTakesThePadding(testCase)
         % Both limits sit near the middle of their decade, so a half-decade
         % data range gains no empty decade.
         lims = [3.2e4 3.2e5];
         lims_expected = lims .* testCase.pad;

         lims_returned = testCase.snaploglims(lims, testCase.pad, 'snap');

         testCase.verifyEqual(lims_returned, lims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_decadesMovesEveryLimit(testCase)
         % decades ignores the gap, so the same limits reach their decades.
         lims = [3.2e4 3.2e5];
         lims_expected = [1e4 1e6];

         lims_returned = testCase.snaploglims(lims, testCase.pad, 'decades');

         testCase.verifyEqual(lims_returned, lims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_badLimitsComeBackUnchanged(testCase, badlims)
         % Zero, a negative value, and a non-finite value have no log10, so
         % the caller keeps the limits it already has.
         lims_returned = testCase.snaploglims(badlims, testCase.pad, 'snap');

         testCase.verifyEqual(lims_returned, badlims)
      end

      function test_unknownPolicyRaisesAnError(testCase)
         % A value the parsers do not allow must not pass unnoticed.
         lims = [1 10];

         testCase.verifyError( ...
            @() testCase.snaploglims(lims, testCase.pad, 'tight'), ...
            'baseflow:snaploglims:unknownAxisLimits')
      end
   end
end
