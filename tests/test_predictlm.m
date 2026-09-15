classdef test_predictlm < matlab.unittest.TestCase
   %TEST_PREDICTLM Test the private predictlm model input types.
   %
   % predictlm is private, so the tests reach it with
   % baseflow.privatefunction. predictlm reads a LinearModel, a struct
   % with the LinearModel field names, or an older Octave coeffs struct.
   % Each input must give the predict response and bounds of the model.

   properties (TestParameter)
      % The model input that predictlm reads.
      inputtype = struct( ...
         'linearModel', 'linearModel', ...
         'modelStruct', 'modelStruct', ...
         'coeffsStruct', 'coeffsStruct')
      % The predictlm bound type and the predict 'Prediction' value that
      % gives the same bounds.
      boundtype = struct( ...
         'confidence', {{'confidence', 'curve'}}, ...
         'prediction', {{'prediction', 'observation'}})
      % Pointwise or simultaneous bounds.
      simultaneous = struct('pointwise', false, 'simultaneous', true)
   end

   properties
      % The private predictlm function handle and the fitted LinearModel.
      predictlm
      mdl
   end

   methods (TestClassSetup)
      function fitModel(testCase)
         % Fit one line with a deterministic scatter, so the residual
         % degrees of freedom (48) differ from the query point count.
         testCase.predictlm = baseflow.privatefunction('predictlm');
         x = transpose(1:50);
         y = 2 + 0.5 * x + sin(x);
         testCase.mdl = fitlm(x, y);
      end
   end

   methods (Test)
      function test_matchesPredict(testCase, inputtype, boundtype, ...
            simultaneous)
         % Each model input gives the predict response and bounds at query
         % points that were not used to fit the model.
         [type, prediction] = boundtype{:};
         xquery = [5; 45];
         alpha = 0.1;
         tolerance = 1e-10;

         [ypred_expected, yconf_expected] = predict(testCase.mdl, ...
            xquery, 'Alpha', alpha, 'Prediction', prediction, ...
            'Simultaneous', simultaneous);
         stats = modelinput(testCase.mdl, inputtype);
         [ypred_returned, yconf_returned] = testCase.predictlm(stats, ...
            xquery, alpha, type, simultaneous);

         testCase.verifyEqual(ypred_returned, ypred_expected, ...
            'AbsTol', tolerance)
         testCase.verifyEqual(yconf_returned, yconf_expected, ...
            'AbsTol', tolerance)
      end
   end
end

function stats = modelinput(mdl, inputtype)
   %MODELINPUT Return the LinearModel MDL as the INPUTTYPE model input.
   %
   % 'linearModel' returns MDL. 'modelStruct' copies the LinearModel field
   % names that predictlm reads. 'coeffsStruct' builds the older Octave
   % regression struct: coeffs columns hold the estimate, standard error,
   % lower and upper 95% bounds, t statistic, and p-value.
   switch inputtype
      case 'linearModel'
         stats = mdl;
      case 'modelStruct'
         stats.Coefficients.Estimate = mdl.Coefficients.Estimate;
         stats.CoefficientCovariance = mdl.CoefficientCovariance;
         stats.MSE = mdl.MSE;
         stats.DFE = mdl.DFE;
      case 'coeffsStruct'
         stats.coeffs = [mdl.Coefficients.Estimate, ...
            mdl.Coefficients.SE, coefCI(mdl), ...
            mdl.Coefficients.tStat, mdl.Coefficients.pValue];
         stats.vcov = mdl.CoefficientCovariance;
         stats.mse = mdl.MSE;
         stats.dfe = mdl.DFE;
   end
end
