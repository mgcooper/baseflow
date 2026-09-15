classdef test_eqstrings < matlab.unittest.TestCase
   %TEST_EQSTRINGS Test the equation label helpers.
   %
   % The suite checks baseflow.aQbString, baseflow.QtString, and
   % baseflow.QtauString. Each helper returns one label: aQbString the
   % -dQ/dt = aQ^b label, QtString the Q(t) label, and QtauString the Q*
   % label.
   %
   % See also: baseflow.aQbString, baseflow.QtString, baseflow.QtauString

   properties (TestParameter)
      % Labels with values. Each case holds the helper, its positional
      % inputs, and the expected label. The [1e-2 1.5] cases use the
      % symbolic Q0 or tau0. The [1250 2] cases check the mantissa for
      % a >= 10 and a numeric Q0 or tau0. The aQbString cases check that
      % math mode closes before e, so e is upright.
      valuecase = struct( ...
         'aQbString_small_a', {{@baseflow.aQbString, {[1e-2 1.5]}, ...
         '-d$Q$/d$t$ = 1e$^{-2}Q^{1.50}$'}}, ...
         'aQbString_large_a', {{@baseflow.aQbString, {[1250 2]}, ...
         '-d$Q$/d$t$ = 1e$^{3}Q^{2.00}$'}}, ...
         'QtString_small_a', {{@baseflow.QtString, {[1e-2 1.5]}, ...
         '$Q(t) = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)} (b=1.50)$'}}, ...
         'QtString_large_a', {{@baseflow.QtString, {[1250 2], 1000}, ...
         '$Q(t) = [1000^{-(b-1)}+a(b-1)t]^{-1/(b-1)} (b=2.00)$'}}, ...
         'QtauString_small_a', {{@baseflow.QtauString, {[1e-2 1.5]}, ...
         '$Q^* = [\tau$/$\tau_0$]$^{-\alpha}$ $(b=1.50)$'}}, ...
         'QtauString_large_a', {{@baseflow.QtauString, {[1250 2], 5}, ...
         '$Q^* = [\tau$/5]$^{-\alpha}$ $(b=2.00)$'}})

      % Symbolic labels. Each case holds the helper and the expected label.
      % The aQb and Q(t) labels equal the baseflow.getstring labels.
      symboliccase = struct( ...
         'aQbString', {{@baseflow.aQbString, ...
         '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$'}}, ...
         'QtString', {{@baseflow.QtString, ...
         '$Q(t) = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)}$'}}, ...
         'QtauString', {{@baseflow.QtauString, ...
         '$Q^* = [\tau$/$\tau_0$]$^{-\alpha}$'}})

      % The three helpers, for the one-output check.
      helper = struct( ...
         'aQbString', @baseflow.aQbString, ...
         'QtString', @baseflow.QtString, ...
         'QtauString', @baseflow.QtauString)
   end

   methods (Test)
      function test_valuelabels(testCase, valuecase)
         % Verify the label when 'printvalues' is true
         [helperfn, inputs, expected] = valuecase{:};

         returned = helperfn(inputs{:}, 'printvalues', true);

         testCase.verifyEqual(returned, expected)
      end

      function test_symboliclabels(testCase, symboliccase)
         % Verify the label when 'printvalues' is false (the default).
         % The [a b] values must not appear in the label.
         [helperfn, expected] = symboliccase{:};

         returned = helperfn([1e-2 1.5]);

         testCase.verifyEqual(returned, expected)
      end

      function test_oneoutput(testCase, helper)
         % Verify that each helper returns one label and no second output
         expected = 'MATLAB:TooManyOutputs';

         testCase.verifyError(@() twooutputs(helper), expected)
      end

      function test_aQbStringRejectsQ0(testCase)
         % Verify that aQbString takes no Q0 input. Q0 only served the
         % Q(t) label, which QtString returns.
         expected = 'MATLAB:InputParser:ParamMustBeChar';

         testCase.verifyError(@() baseflow.aQbString([1250 2], 1000, ...
            'printvalues', true), expected)
      end
   end
end

%% LOCAL FUNCTIONS
function twooutputs(helperfn)
   %TWOOUTPUTS Request two outputs from an equation label helper.
   %
   % A function handle call with two outputs must run in a function body,
   % because an anonymous function cannot request two outputs.
   [~, ~] = helperfn([1250 2], 'printvalues', true);
end
