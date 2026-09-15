function [Fit, stats] = fitlm_octmat(X, y, alpha)
   %FITLM_OCTMAT Fit linear model in an Octave or Matlab compatible way.
   %
   %  [FIT, STATS] = FITLM_OCTMAT(X, Y, ALPHA) Fits the responses in y to the
   %  design matrix X using linear least squares. The input data, fitted y
   %  values, and 100(1-ALPHA)% confidence interval are returned in the output
   %  FIT. The fitted coefficients, standard error, 100(1-ALPHA)% confidence
   %  interval, t-statistic, p-values, and and variance-covariance matrix are
   %  returned in STATS. ALPHA is optional, default 0.05.
   %
   % See also: fitlm, predict

   if nargin < 3 || isempty(alpha); alpha = 0.05; end

   % Compute fitted line and CIs. fitlm returns a LinearModel in MATLAB and
   % in the Octave statistics package, so one call path serves both.
   mdl = fitlm(X, y);
   [ypred, yconf] = predict(mdl, X, 'alpha', alpha);

   % Copy the model properties into a struct with the same field names, so
   % callers read one struct in MATLAB and Octave. The CI uses alpha, like
   % the yCI bounds.
   stats.Coefficients.Estimate = mdl.Coefficients.Estimate;
   stats.Coefficients.SE = mdl.Coefficients.SE;
   stats.Coefficients.CI = coefCI(mdl, alpha);
   stats.Coefficients.tStat = mdl.Coefficients.tStat;
   stats.Coefficients.pValue = mdl.Coefficients.pValue;
   stats.CoefficientCovariance = mdl.CoefficientCovariance; % covariance matrix
   stats.MSE = mdl.MSE; % mean square error
   stats.DFE = mdl.DFE; % error degrees of freedom (N-2)

   Fit.X = X;
   Fit.y = y;
   Fit.yFit = ypred;
   Fit.yCI = yconf;

   % If the cell array (first output) of fitlm is used in octave:
   % coeff = [mdl{2:3, 2}]; % this might work in matlab too

   % Fit.Predictor = x;
   % Fit.Response = y;
   % Fit.Predicted = ypred;
   % Fit.Interval = yconf;
   % Fit.Design = [ones(N,1), x(:)];
end

