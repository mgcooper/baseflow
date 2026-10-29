classdef test_bootstrappercentiles < matlab.unittest.TestCase
   %TEST_BOOTSTRAPPERCENTILES Literal quantiles and real public bootstrap use.
   properties (TestParameter)
      invalid = {NaN,Inf,-Inf}
   end
   methods (TestMethodSetup)
      function preserveState(testCase)
         %PRESERVESTATE Restore the random state after each test.
         rng_original = rng;
         testCase.addTeardown(@() rng(rng_original));
      end
   end
   methods (Test)
      function literalSkewedQuantiles(testCase)
         %LITERALSKEWEDQUANTILES Verify fixed endpoints for a skewed sample.
         probabilities_expected = [0.025,0.975];
         method_expected = 'midpoint';
         bounds_expected = [1.5,519.5];
         sampleCount_expected = 40;
         reps = struct('b',[1:39,1000]');
         returned = baseflow.internal.bootstrappercentiles(reps);
         testCase.verifyEqual( ...
            returned.probabilities,probabilities_expected);
         testCase.verifyEqual(returned.method,method_expected);
         testCase.verifyEqual(returned.b.bounds,bounds_expected);
         testCase.verifyTrue(returned.b.available);
         testCase.verifyEqual(returned.b.sampleCount,sampleCount_expected);
         testCase.verifyEqual(returned.b.invalidCount,0);
      end
      function constantQuantiles(testCase)
         %CONSTANTQUANTILES Keep both endpoints at the constant value.
         bounds_expected = [7,7];
         returned = baseflow.internal.bootstrappercentiles( ...
            struct('b',7*ones(40,1)));
         testCase.verifyEqual(returned.b.bounds,bounds_expected);
      end
      function neverDiscardsInvalidSamples(testCase,invalid)
         %NEVERDISCARDSINVALIDSAMPLES Mark nonfinite replicates unavailable.
         reason_expected = 'nonfiniteReplicates';
         sampleCount_expected = 40;
         returned = baseflow.internal.bootstrappercentiles( ...
            struct('b',[1:39,invalid]'));
         testCase.verifyFalse(returned.b.available);
         testCase.verifyTrue(all(isnan(returned.b.bounds)));
         testCase.verifyEqual(returned.b.reason,reason_expected);
         testCase.verifyEqual(returned.b.sampleCount,sampleCount_expected);
         testCase.verifyEqual(returned.b.invalidCount,1);
      end
      function emptyReplicatesHaveNoBounds(testCase)
         %EMPTYREPLICATESHAVENOBOUNDS Report an empty sample explicitly.
         reason_expected = 'emptyReplicates';
         returned = baseflow.internal.bootstrappercentiles(struct('b',[]));
         testCase.verifyEqual(returned.b.reason,reason_expected);
         testCase.verifyFalse(returned.b.available);
         testCase.verifyEqual(returned.b.sampleCount,0);
      end
      function publicBootstrapUsesLiteralOrderWeights(testCase)
         %PUBLICBOOTSTRAPUSESLITERALORDERWEIGHTS Check public output bounds.
         sampleCount_expected = 50;
         relativeTolerance = 2e-14;
         bTolerance = 2e-16;
         tauTolerance = 2e-14;
         u = ((1:200)'-0.5)/200;
         x = 10*(1-u).^(-1/2.5);
         rng(71);
         fit_returned = baseflow.plfitb(x,'bootfit',true,'bootreps',50);
         names = {'alpha','b','tau0','tau','ntail'};
         for k = 1:numel(names)
            name = names{k}; values = sort(fit_returned.reps.(name));
            % For n=50, midpoint knots give these fixed endpoint weights.
            expected = [0.25*values(1)+0.75*values(2), ...
               0.75*values(49)+0.25*values(50)];
            summary_returned = fit_returned.Percentiles.(name);
            testCase.verifyTrue(summary_returned.available);
            testCase.verifyEqual(summary_returned.bounds,expected, ...
               'RelTol',relativeTolerance);
            testCase.verifyEqual( ...
               summary_returned.sampleCount,sampleCount_expected);
         end
         % Propagation fields remain one-sigma quantities.
         bSigma_returned = fit_returned.b_H-fit_returned.b;
         bSigma_expected = fit_returned.BootFit.b_sig;
         tauSigma_returned = fit_returned.tau_H-fit_returned.tau;
         tauSigma_expected = fit_returned.BootFit.tau_sig;
         testCase.verifyEqual(bSigma_returned,bSigma_expected, ...
            'AbsTol',bTolerance);
         testCase.verifyEqual(tauSigma_returned,tauSigma_expected, ...
            'AbsTol',tauTolerance);
      end
      function publicPoleKeepsFiniteParameterSummaries(testCase)
         %PUBLICPOLEKEEPSFINITEPARAMETERSUMMARIES Limit pole effects to tau.
         reason_expected = 'tauPole';
         sampleCount_expected = 50;
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'baseflow:expectedtau:tauPole'));
         u = ((1:200)'-0.5)/200; x = 10*(1-u).^(-1/1.05);
         rng(1);
         fit_returned = baseflow.plfitb(x,'bootfit',true,'bootreps',50);
         poleCount_expected = nnz(fit_returned.reps.alpha<=2);
         testCase.verifyGreaterThan(poleCount_expected,0);
         testCase.verifyFalse(fit_returned.Percentiles.tau.available);
         testCase.verifyEqual( ...
            fit_returned.Percentiles.tau.reason,reason_expected);
         testCase.verifyEqual( ...
            fit_returned.Percentiles.tau.poleCount,poleCount_expected);
         testCase.verifyEqual( ...
            fit_returned.Percentiles.tau.invalidCount,poleCount_expected);
         testCase.verifyNumElements( ...
            fit_returned.reps.tau,sampleCount_expected);
         testCase.verifyTrue(fit_returned.Percentiles.b.available);
         testCase.verifyTrue(fit_returned.Percentiles.alpha.available);
      end
      function noBootstrapDoesNotInventEvidence(testCase)
         %NOBOOTSTRAPDOESNOTINVENTEVIDENCE Keep unavailable bounds explicit.
         reason_expected = 'notBootstrapped';
         u = ((1:200)'-0.5)/200; x = 10*(1-u).^(-1/2.5);
         fit_returned = baseflow.plfitb(x);
         testCase.verifyFalse(fit_returned.Percentiles.b.available);
         testCase.verifyEqual( ...
            fit_returned.Percentiles.b.reason,reason_expected);
         testCase.verifyEqual(fit_returned.Percentiles.b.sampleCount,0);
         testCase.verifyEqual(fit_returned.b_L,fit_returned.b);
         testCase.verifyEqual(fit_returned.b_H,fit_returned.b);
         [b_returned,alpha_returned,tau0_returned] = baseflow.plfitb(x);
         returned = [b_returned,alpha_returned,tau0_returned];
         expected = [fit_returned.b,fit_returned.alpha,fit_returned.tau0];
         testCase.verifyEqual(returned,expected);
      end
   end
end
