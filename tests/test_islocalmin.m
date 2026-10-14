classdef test_islocalmin < matlab.unittest.TestCase
   %TEST_ISLOCALMIN Test baseflow/private/islocalmin.m
   %
   % The private islocalmin wraps peakfinder, because Octave has no
   % islocalmin. It must find the same interior minima as the MATLAB
   % function of the same name. tests/test_islocalmax.m holds the same
   % signals for the maxima.

   properties (TestParameter)
      % Short signals with one peak, one valley, or several extrema. The
      % one-extremum signals check the peakfinder monotone branch.
      ExtremaSignal = struct( ...
         'onepeak', [1 2 3 2 1], ...
         'peakthenfall', [2 3 1 0 -1], ...
         'threepoints', [0 1 0], ...
         'twopeaks', [1 2 3 2 5 1], ...
         'peakvalleypeak', [10 12 15 13 11 12 11], ...
         'onevalley', [10 9 8 9 10]);
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_islocalextrema(testCase, ExtremaSignal)

         % The private peakfinder wrappers must find the same interior
         % extrema as the MATLAB functions of the same name
         customfunction = baseflow.privatefunction('islocalmin');
         expected = islocalmin(ExtremaSignal);
         returned = customfunction(ExtremaSignal);
         testCase.verifyEqual(returned, expected)
      end
   end
end
