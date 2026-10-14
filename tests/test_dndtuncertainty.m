function tests = test_dndtuncertainty
   %TEST_DNDTUNCERTAINTY Test the input checks of baseflow.dndtuncertainty.
   %
   % The coverage-factor behavior on the Kuparuk workflow is an integration
   % check in TestBaseflow.
   tests = functiontests(localfunctions);
end

function test_dndtuncertaintyInvalidAlpha(testCase)
   % dndtuncertainty rejects an alpha outside (0, 1) before it uses the
   % other inputs, so empty placeholders suffice.
   alpha_invalid = 1.5;
   testCase.verifyError(@() baseflow.dndtuncertainty([], [], [], [], ...
      [], [], alpha_invalid), 'baseflow:dndtuncertainty:invalidAlpha')
end
