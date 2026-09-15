classdef test_fillnans < matlab.unittest.TestCase
   %TEST_FILLNANS Test the private fillnans helper.
   %
   % fillnans is private, so the tests reach it with
   % baseflow.privatefunction. The input is a linear ramp with nan runs. A
   % spline through linear data is linear, so each filled value equals the
   % ramp value. Each case runs with a column vector and a row vector.

   properties (TestParameter)
      % Each case holds the indices of the nan values in a 10-sample ramp
      % and the indices that fillnans fills when fmax is 2. fillnans fills
      % interior runs of length fmax or less. It leaves longer runs and
      % leading and trailing runs unchanged.
      gap = struct( ...
         'shorterThanFmax', {{4, 4}}, ...
         'equalToFmax', {{[4; 5], [4; 5]}}, ...
         'longerThanFmax', {{[4; 5; 6], []}}, ...
         'leadingRun', {{[1; 2], []}}, ...
         'trailingRun', {{[9; 10], []}}, ...
         'interiorAndTrailing', {{[4; 10], 4}}, ...
         'leadingInteriorTrailing', {{[1; 4; 10], 4}}, ...
         'allNan', {{transpose(1:10), []}})

      % The ramp size for a column vector and for a row vector.
      shape = struct('column', [10 1], 'row', [1 10])
   end

   properties
      % The private fillnans function handle.
      fillnans
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.fillnans = baseflow.privatefunction('fillnans');
      end
   end

   methods (Test)
      function test_fillsInteriorRuns(testCase, gap, shape)
         % An interior nan run of length fmax or less is filled. A longer
         % run, a leading run, and a trailing run are left unchanged. The
         % output has the input shape.
         [inan, ifilled] = gap{:};
         fmax = 2;
         tol = 1e-12;
         ramp = reshape(1:prod(shape), shape);
         q = ramp;
         q(inan) = nan;
         expected = ramp;
         expected(setdiff(inan, ifilled)) = nan;

         returned = testCase.fillnans(q, fmax);
         testCase.verifyEqual(returned, expected, 'AbsTol', tol)
      end

      function test_emptyInput(testCase)
         % getevents passes an empty vector when every flow value is nan.
         % fillnans returns the empty vector unchanged.
         fmax = 2;
         expected = zeros(0, 1);

         returned = testCase.fillnans(expected, fmax);
         testCase.verifyEqual(returned, expected)
      end
   end
end
