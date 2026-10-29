function tests = test_fitphi
   %TEST_FITPHI Test the drainable porosity of baseflow.fitphi.
   %
   % fitphi solves for phi from early-time and late-time recession
   % intercepts. The inputs are the Kuparuk basin constants of the demos
   % and recession intercepts on the scale of the example data.
   tests = functiontests(localfunctions);
end

function test_fitphiNominal(testCase)
   % The PK62 early / BS03 late (b=1) pair returns one interior phi with
   % its description; the default RS05 pair returns an interior phi for
   % the fitted late-time exponent range.
   [A, D, L, a1, a2, b2_linear] = kuparukinputs();
   b2_fitted = 1.278;
   solns_expected = {'PK62_BS03'};
   ndesc_expected = 2;
   phimin = 0;
   phimax = 1;

   [phi_returned, solns_returned, desc_returned] = baseflow.fitphi( ...
      a1, a2, b2_linear, A, D, L, 'soln1', 'PK62', 'soln2', 'BS03');
   testCase.verifyEqual(solns_returned, solns_expected)
   testCase.verifyNumElements(desc_returned, ndesc_expected)
   testCase.verifyGreaterThan(phi_returned, phimin)
   testCase.verifyLessThan(phi_returned, phimax)

   phi_returned = baseflow.fitphi(a1, a2, b2_fitted, A, D, L);
   testCase.verifyGreaterThan(phi_returned, phimin)
   testCase.verifyLessThan(phi_returned, phimax)
end

function test_fitphiUnsupportedPairErrors(testCase)
   % b2 = 1 with the default RS05 solutions remaps to a pair with no
   % derived formula; the guard raises the documented error instead of
   % returning unassigned outputs.
   % fitphi warns before it falls back, and this test asks for the pair
   % that triggers the fallback, so the warning is expected output rather
   % than a problem to print.
   testCase.applyFixture(matlab.unittest.fixtures.SuppressedWarningsFixture( ...
      'baseflow:fitphi:incompatibleLateTimeSolution'));
   [A, D, L, a1, a2, b2_linear] = kuparukinputs();
   expected = 'baseflow:fitphi:unsupportedSolution';
   testCase.verifyError(@() baseflow.fitphi(a1, a2, b2_linear, A, D, L), ...
      expected)
end

function [A, D, L, a1, a2, b2_linear] = kuparukinputs()
   %KUPARUKINPUTS Basin constants and recession intercepts of the tests.
   %
   %  The Kuparuk basin area [m2], aquifer depth [m], and stream length
   %  [m] from a drainage density of 0.8 per km, and the early-time and
   %  late-time a values with the linear (b = 1) late-time exponent.
   A = 8.6545e9;
   D = 0.5;
   L = A*0.8/1000;
   a1 = 1e-12;
   a2 = 1.05e-3;
   b2_linear = 1;
end
