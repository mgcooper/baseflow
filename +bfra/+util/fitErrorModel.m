function [bestModel, bestFit, fitResults] = fitErrorModel(time, flow)
% Fit the model -dQ/dt = aQ^b using proportional and combined error models
% and return the best model, its fit, and the fit statistics.

% Calculate the first derivative of the flow data
dQdt = -diff(flow) ./ days(diff(time));

% Remove the last flow value to match the length of dQdt
flow = flow(1:end-1);

% Define the model function
modelFun = @(params, Q) params(1) * Q.^params(2);

% Initial guess for the parameters c and d
initParams = [1, 1];

% Initialize the fitting options
opts = statset('nlinfit');

% % Fit the model using nlinfit with the proportional and combined error models
% testModels = ["Constant","Proportional","Combined"];
% for n = 1:numel(testModels)
%    [params,resids] = nlinfit(flow, dQdt, modelFun, initParams, opts, ...
%       "ErrorModel", testModels(n));
%    fitResults(n,:) = calculateFitStatistics(flow, resids, params, testModels(n));
% end

% Fit the model using nlinfit with the proportional and combined error models
[consParams, consResids] = nlinfit(flow, dQdt, modelFun, initParams, opts, 'ErrorModel', 'constant');
[propParams, propResids] = nlinfit(flow, dQdt, modelFun, initParams, opts, 'ErrorModel', 'proportional');
[combParams, combResids] = nlinfit(flow, dQdt, modelFun, initParams, opts, 'ErrorModel', 'combined');

% Compute the fit statistics
consStats = calculateFitStatistics(flow, consResids, consParams, "Constant");
propStats = calculateFitStatistics(flow, propResids, propParams, "Proportional");
combStats = calculateFitStatistics(flow, combResids, combParams, "Combined");

% Combine the results into a table
fitResults = [consStats; propStats; combStats];

% Choose the best model based on the lowest AIC
[~, bestIdx] = min(fitResults.AIC);
bestModel = fitResults.ErrorModel(bestIdx);
bestFit = [fitResults.a(bestIdx) fitResults.b(bestIdx)];

% % Original selection procedure: 
% if fitResults.AIC(1) <= fitResults.AIC(2) && fitResults.BIC(1) <= fitResults.BIC(2)
%    bestModel = fitResults.ErrorModel(1);
%    bestFit = [fitResults.a(1) fitResults.b(1)];
% else
%    bestModel = fitResults.ErrorModel(2);
%    bestFit = [fitResults.a(2) fitResults.b(2)];
% end

bfra.util.plotComparisonResults(time, flow, dQdt, fitResults);

end


function fitStats = calculateFitStatistics(flow, residuals, params, ErrorModel)

% Calculate R-squared values, RMSE, AIC, and BIC
n = length(residuals);
k = numel(params);
SSE = sum(residuals.^2);
RMSE = sqrt(mean(residuals.^2));
SStotal = sum((flow - mean(flow)).^2);
Rsquared = 1 - SSE / SStotal;
AIC = n * log(SSE / n) + 2 * k;
BIC = n * log(SSE / n) + k * log(n);
a = params(1);
b = params(2);
fitStats = table(ErrorModel, RMSE, Rsquared, AIC, BIC, a, b);
end
