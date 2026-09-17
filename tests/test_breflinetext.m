classdef test_breflinetext < matlab.unittest.TestCase
   %TEST_BREFLINETEXT Test the b value text of a reference-line label.
   %
   % breflinetext is private, so the tests reach it with
   % baseflow.privatefunction. A theoretical b carries the digits it needs
   % and no more, and an estimate carries b-hat, so a reader can tell the
   % fitted line from the reference lines it is drawn against.

   properties (TestParameter)
      % Each case holds a b value and the digits its label shows.
      referencevalue = struct( ...
         'linearreservoir', {{1, 'b=1'}}, ...
         'earlytime', {{3, 'b=3'}}, ...
         'boussinesq', {{3/2, 'b=1.5'}}, ...
         'fittedvalue', {{1.3541, 'b=1.35'}})
   end

   properties
      % The private breflinetext function handle.
      breflinetext
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.breflinetext = baseflow.privatefunction('breflinetext');
      end
   end

   methods (Test)
      function test_referenceValueShowsTheDigitsItNeeds(testCase, ...
            referencevalue)
         % A whole number shows none, a half shows one, and any other
         % value shows two.
         [b, text_expected] = referencevalue{:};
         isestimate = false;

         returned = testCase.breflinetext(b, isestimate, 'tex');

         testCase.verifyEqual(returned, text_expected)
      end

      function test_estimateCarriesTheHat(testCase)
         % The fitted line is an estimate, so its label says so and keeps
         % two decimals whatever the value.
         b = 1;
         isestimate = true;
         text_expected = '$b=1.00$ ($\hat{b}$)';

         returned = testCase.breflinetext(b, isestimate, 'latex');

         testCase.verifyEqual(returned, text_expected)
      end

      function test_latexWrapsTheValueInMathDelimiters(testCase)
         % The latex interpreter needs the delimiters, and the tex
         % interpreter Octave uses would print them.
         b = 3;
         isestimate = false;
         latex_expected = '$b=3$';
         tex_expected = 'b=3';

         testCase.verifyEqual( ...
            testCase.breflinetext(b, isestimate, 'latex'), latex_expected)
         testCase.verifyEqual( ...
            testCase.breflinetext(b, isestimate, 'tex'), tex_expected)
      end

      function test_texEstimateNamesTheHatInWords(testCase)
         % Octave draws no latex, so the hat is spelled out.
         b = 1.3541;
         isestimate = true;
         text_expected = 'b=1.35 (bhat)';

         returned = testCase.breflinetext(b, isestimate, 'tex');

         testCase.verifyEqual(returned, text_expected)
      end
   end
end
