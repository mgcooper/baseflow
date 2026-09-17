classdef test_islabelcolor < matlab.unittest.TestCase
   %TEST_ISLABELCOLOR Test the private islabelcolor validator.
   %
   % islabelcolor is private, so the tests reach it with
   % baseflow.privatefunction. A plotting function accepts an RGB triplet,
   % a color name, or empty for its default color.

   properties (TestParameter)
      % Each case holds a value and the expected result.
      color = struct( ...
         'triplet', {{[0 0 0], true}}, ...
         'whiteTriplet', {{[1 1 1], true}}, ...
         'name', {{'k', true}}, ...
         'stringName', {{"black", true}}, ...
         'empty', {{[], true}}, ...
         'fourElements', {{[0 0 0 1], false}}, ...
         'outOfRange', {{[0 0 255], false}}, ...
         'scalar', {{0.5, false}})
   end

   properties
      % The private islabelcolor function handle.
      islabelcolor
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.islabelcolor = baseflow.privatefunction('islabelcolor');
      end
   end

   methods (Test)
      function test_acceptsColorValues(testCase, color)
         % Only a triplet in [0, 1], a name, or empty is a color.
         [value, expected] = color{:};

         returned = testCase.islabelcolor(value);

         testCase.verifyEqual(returned, expected)
      end
   end
end
