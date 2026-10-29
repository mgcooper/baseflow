classdef test_specialfunctions < matlab.unittest.TestCase
   %TEST_SPECIALFUNCTIONS Test the Rupp and Selker (2005) constants.
   %
   % Rupp and Selker (2005) Table 1 lists the early-time constant Phi1
   % (weighted residual with m = 1) and the late-time constant Phi2 for
   % seven values of n in k(z) = kD*(z/D)^n. specialfunctions returns
   % fR1 = (n+1)*Phi1, the prefactor of their eq 54 for a1. It returns
   % fR2 = 2*Phi2, the form their eq 57 for a2 takes in fitphi and
   % aquiferprops. For a homogeneous aquifer (n = 0), fR2 reduces to the
   % Brutsaert and Nieber (1977) constant 4.804, which fitphi and
   % aquiferprops use for the BS04 solution.

   properties (TestParameter)
      % The rows of Table 1: n, Phi1, and Phi2 as published.
      Table1 = struct( ...
         'n0', struct('n', 0, 'Phi1', 1.108, 'Phi2', 2.402), ...
         'n1_4', struct('n', 1/4, 'Phi1', 1.337, 'Phi2', 2.538), ...
         'n1_2', struct('n', 1/2, 'Phi1', 1.588, 'Phi2', 2.690), ...
         'n1', struct('n', 1, 'Phi1', 2.151, 'Phi2', 3.030), ...
         'n2', struct('n', 2, 'Phi1', 3.528, 'Phi2', 3.787), ...
         'n4', struct('n', 4, 'Phi1', 7.279, 'Phi2', 5.445), ...
         'n64', struct('n', 64, 'Phi1', 739.8, 'Phi2', 63.17))
   end

   methods (Test)
      function test_earlyTimeConstantMatchesTable1(testCase, Table1)
         % fR1 has no pole at n = 1 and stays positive for large n.
         expected = Table1.Phi1;

         returned = baseflow.specialfunctions('fR1', Table1.n)/(Table1.n + 1);

         testCase.verifyEqual(returned, expected, ...
            'AbsTol', halfunit(expected))
      end

      function test_lateTimeConstantMatchesTable1(testCase, Table1)
         % fR2 carries the exponent n+3 on the Beta function.
         expected = Table1.Phi2;

         returned = baseflow.specialfunctions('fR2', Table1.n)/2;

         testCase.verifyEqual(returned, expected, ...
            'AbsTol', halfunit(expected))
      end

      function test_lateTimeConstantAtHomogeneousLimit(testCase)
         % 4.804 is published to three decimals, 0.001 below the 4.805 of
         % the Rupp and Selker formula, so allow 1e-3 relative.
         expected = 4.804;
         bntol = 1e-3;

         returned = baseflow.specialfunctions('fR2', 0);

         testCase.verifyEqual(returned, expected, 'RelTol', bntol)
      end
   end
end

function tol = halfunit(value)
   %HALFUNIT Half a unit in the fourth significant figure of a value.
   %
   % Table 1 prints every value to four significant figures, so a correct
   % constant lies within half a unit of the last printed digit.
   tol = 0.5*10^(floor(log10(value)) - 3);
end
