classdef test_peakfinder < matlab.unittest.TestCase
   %TEST_PEAKFINDER Test the vendored +deps/peakfinder function.
   %
   % The tests cover the empty-input path and one nominal peak case as a
   % reference for the algorithm's behavior. The function signature declares
   % named outputs, so the empty-input path must assign those outputs, not
   % varargout. An assignment to varargout makes empty input error instead
   % of returning empty results.

   properties (TestParameter)
      % Each case holds an input signal and the index of its peak. Empty
      % input returns empty outputs, not an error. peakfinder returns the
      % index and magnitude of one clear interior maximum.
      signal = struct( ...
         'empty', {{[], []}}, ...
         'simplepeak', {{[0 1 3 1 0], 3}})
   end

   methods (Test)
      function test_findsPeak(testCase, signal)
         % peakfinder returns each peak index and the magnitude there.
         x = signal{1};
         locs_expected = signal{2};
         mags_expected = x(locs_expected);
         [locs_returned, mags_returned] = baseflow.deps.peakfinder(x);
         testCase.verifyEqual(locs_returned, locs_expected)
         testCase.verifyEqual(mags_returned, mags_expected)
      end

      function test_emptyThroughIslocalmax(testCase)
         % baseflow/private/islocalmax indexes with the locations that
         % peakfinder returns. Empty input must produce an empty logical,
         % not an error.
         customislocalmax = baseflow.privatefunction('islocalmax');
         returned = customislocalmax([]);
         testCase.verifyEmpty(returned)
         testCase.verifyClass(returned, 'logical')
      end
   end
end
