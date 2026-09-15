classdef test_smoothnoise < matlab.unittest.TestCase
   %TEST_SMOOTHNOISE Test the private smoothnoise helper.
   %
   % smoothnoise is private, so the tests reach it with
   % baseflow.privatefunction. The annual tests pass the same two years of
   % data in each accepted layout and compare every year with smoothdata
   % applied to that year alone. A layout that mixes days of different
   % years fails this comparison.

   properties (TestParameter)
      % Each case holds a layout name, a function that converts a
      % numyears-by-365 matrix to that layout, and its inverse.
      layout = struct( ...
         'rowsAreYears', {{@(X) X, @(Y) Y}}, ...
         'colsAreYears', {{@(X) transpose(X), @(Y) transpose(Y)}}, ...
         'column', {{@(X) reshape(transpose(X), [], 1), ...
         @(Y) transpose(reshape(Y, 365, []))}}, ...
         'row', {{@(X) reshape(transpose(X), 1, []), ...
         @(Y) transpose(reshape(Y, 365, []))}})
   end

   properties
      % The private smoothnoise function handle, two years of daily data
      % with one year per row, and the expected smoothed years and windows.
      smoothnoise
      X
      Y_expected
      win_expected
   end

   methods (TestClassSetup)
      function makeyears(testCase)
         % Two years of deterministic noisy data with different shapes and
         % means. The first year has negative values, so smoothnoise does
         % not clip y at zero.
         testCase.smoothnoise = baseflow.privatefunction('smoothnoise');
         numyears = 2;
         days = 1:365;
         testCase.X = [sin(days.^2); 5 + cos(days.^2)];
         testCase.Y_expected = nan(size(testCase.X));
         testCase.win_expected = nan(numyears, 1);
         for n = 1:numyears
            [testCase.Y_expected(n, :), testCase.win_expected(n)] = ...
               smoothdata(testCase.X(n, :), 2, 'sgolay');
         end
      end
   end

   methods (Test)
      function test_annualSmoothsEachYear(testCase, layout)
         % Each layout returns y in its own size, each year matches the
         % year smoothed alone, and win holds one window per year.
         [tolayout, fromlayout] = layout{:};
         x = tolayout(testCase.X);

         [y, win_returned] = testCase.smoothnoise(x, 'annual');

         size_returned = size(y);
         size_expected = size(x);
         testCase.verifyEqual(size_returned, size_expected)
         Y_returned = fromlayout(y);
         testCase.verifyEqual(Y_returned, testCase.Y_expected)
         testCase.verifyEqual(win_returned, testCase.win_expected)
      end

      function test_noMethod(testCase)
         % With no method input, smoothnoise uses the sgolay filter, which
         % returns a linear signal unchanged and keeps the nan element.
         nsamples = 50;
         inan = 10;
         tol = 1e-10;
         x = transpose(1:nsamples);
         x(inan) = nan;
         expected = x;

         returned = testCase.smoothnoise(x);
         testCase.verifyEqual(returned, expected, 'AbsTol', tol)
      end

      function test_annualNoWholeYearErrors(testCase)
         % A size with no whole number of 365-day years raises the size
         % error. The error has no identifier, so the test compares the
         % message.
         nsamples = 100;
         x = transpose(1:nsamples);
         expected = 'the data size is not an even divisor of 365';

         try
            testCase.smoothnoise(x, 'annual');
            returned = '';
         catch me
            returned = me.message;
         end
         testCase.verifyEqual(returned, expected)
      end
   end
end
