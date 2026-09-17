classdef test_siUnitsToTex < matlab.unittest.TestCase
   %TEST_SIUNITSTOTEX Test the private siUnitsToTex unit label helper.
   %
   % siUnitsToTex is private, so the tests reach it with
   % baseflow.privatefunction. Each case checks the tex string for one unit.
   % hyetograph passes units such as 'm3 d-1' here for its axis labels.

   properties (TestParameter)
      % Each case holds a unit string and its expected tex string. The
      % MATLAB path wraps each letter group and each exponent in braces.
      unit = struct( ...
         'positiveExponent', {{'m2', '{m}^{{2}}'}}, ...
         'negativeExponent', {{'mm d-1', '{mm} {d}^{-{1}}'}}, ...
         'mixedExponents', {{'m3 s-1', '{m}^{{3}} {s}^{-{1}}'}}, ...
         'noExponent', {{'mm', '{mm}'}})
   end

   properties
      % The private siUnitsToTex function handle.
      siUnitsToTex
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.siUnitsToTex = baseflow.privatefunction('siUnitsToTex');
      end
   end

   methods (Test)
      function test_texString(testCase, unit)
         % Each exponent gets one pair of braces, and a negative exponent
         % keeps its minus sign inside the superscript.
         % siUnitsToTex takes and returns a cell array of units.
         [unitstr, labelstr] = unit{:};
         expected = {labelstr};
         returned = testCase.siUnitsToTex({unitstr});
         testCase.verifyEqual(returned, expected)
      end
   end
end
