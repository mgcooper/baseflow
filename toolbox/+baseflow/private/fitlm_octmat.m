function [Fit, stats] = fitlm_octmat(X, y, alpha)
   %FITLM_OCTMAT Fit linear model in an Octave or Matlab compatible way.
   %
   %  [FIT, STATS] = FITLM_OCTMAT(X, Y, ALPHA) Fits the responses in y to the
   %  design matrix X using linear least squares. The input data, fitted y
   %  values, and 95% confidence interval are returned in the output FIT. The
   %  fitted coefficients, standard error, confidence interval, t-statistic,
   %  p-values, and and variance-covariance matrix are returned in STATS. 
   %
   % See also: fitlm, predict

   if nargin < 3 || isempty(alpha); alpha = 0.05; end

   % Compute fitted line and CIs
   if isoctave
      [~, mdl] = fitlm(X, y, 'display', 'off', 'alpha', alpha);
      [ypred, yconf] = predictlm(mdl, X, alpha);

      stats.Coefficients.Estimate = mdl.coeffs(:, 1);
      stats.Coefficients.SE = mdl.coeffs(:, 2);
      stats.Coefficients.CI = mdl.coeffs(:, 3:4);
      stats.Coefficients.tStat = mdl.coeffs(:, 5);
      stats.Coefficients.pValue = mdl.coeffs(:, 6);
      stats.CoefficientCovariance = mdl.vcov; % covariance matrix
      stats.MSE = mdl.mse; % mean square error
      stats.DFE = mdl.dfe; % error degrees of freedom (N-2)
   else
      mdl = fitlm(X, y);
      [ypred, yconf] = predict(mdl, X, 'alpha', alpha);

      stats.Coefficients.Estimate = mdl.Coefficients.Estimate;
      stats.Coefficients.SE = mdl.Coefficients.SE;
      stats.Coefficients.CI = mdl.coefCI; % coefCI(mdl,alpha);
      stats.Coefficients.tStat = mdl.Coefficients.tStat;
      stats.Coefficients.pValue = mdl.Coefficients.pValue;
      stats.CoefficientCovariance = mdl.CoefficientCovariance;
      stats.MSE = mdl.MSE;
      stats.DFE = mdl.DFE;
   end

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

