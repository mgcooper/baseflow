classdef test_tocolumn < matlab.unittest.TestCase
   %TEST_TOCOLUMN Test the private tocolumn helper.
   %
   % tocolumn is private, so the tests reach it with
   % baseflow.privatefunction. tocolumn returns Array(:), so each expected
   % column lists the input elements in column-major order.

   properties (TestParameter)
      % Each case holds an input and its expected column. A row becomes a
      % column; a column and a scalar are unchanged. Matrices and N-D arrays
      % unroll in column-major order. Empty inputs return a 0-by-1 column of
      % the same class. Cell, char, and logical rows keep their class.
      arraycase = struct( ...
         'row', {{[1, 2, 3], [1; 2; 3]}}, ...
         'column', {{[4; 5; 6], [4; 5; 6]}}, ...
         'scalar', {{7, 7}}, ...
         'matrix', {{[1, 3; 2, 4], [1; 2; 3; 4]}}, ...
         'ndArray', {{cat(3, [1, 3; 2, 4], [5, 7; 6, 8]), ...
         [1; 2; 3; 4; 5; 6; 7; 8]}}, ...
         'empty', {{[], zeros(0, 1)}}, ...
         'rowEmpty', {{zeros(1, 0), zeros(0, 1)}}, ...
         'cellRow', {{{'a', 'b'}, {'a'; 'b'}}}, ...
         'charRow', {{'ab', ['a'; 'b']}}, ...
         'logicalRow', {{[true, false], [true; false]}})
   end

   properties
      % The private tocolumn function handle.
      tocolumn
   end

   methods (TestClassSetup)
      function gettocolumn(testCase)
         % Store the private function handle once for every test.
         testCase.tocolumn = baseflow.privatefunction('tocolumn');
      end
   end

   methods (Test)
      function test_column(testCase, arraycase)
         % tocolumn returns the input elements as a column.
         [array, expected] = arraycase{:};
         returned = testCase.tocolumn(array);
         testCase.verifyEqual(returned, expected)
      end

      function test_missingInput(testCase)
         % tocolumn requires one input.
         errid = 'MATLAB:minrhs';
         testCase.verifyError(@() testCase.tocolumn(), errid)
      end
   end
end
