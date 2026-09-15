function [ypred, yconf] = predictlm(stats, x, alpha, type, option)
   %PREDICTLM Predict linear model response with confidence bounds.
   %
   % Syntax
   %
   %     [ypred, yconf] = predictlm(stats, x)
   %     [ypred, yconf] = predictlm(stats, x, alpha)
   %     [ypred, yconf] = predictlm(stats, x, alpha, type)
   %     [ypred, yconf] = predictlm(stats, x, alpha, type, option)
   %
   % Description
   %
   %     [ypred, yconf] = predictlm(stats, x) evaluates the linear model in
   %     stats at the values x and returns the predicted response ypred and
   %     the confidence bounds yconf = [lower upper]. stats is a
   %     single-predictor linear model with an intercept. It can be a
   %     fitlm model object in MATLAB or Octave. It can be a struct with
   %     the fields Coefficients.Estimate, CoefficientCovariance, MSE, and
   %     DFE. It can also be the regression struct that earlier Octave
   %     statistics packages return, with the fields coeffs, vcov, mse, and
   %     dfe. The bounds use the residual degrees of freedom of the fit, so
   %     x can hold any predictor values.
   %
   %     [ypred, yconf] = predictlm(stats, x, alpha, type, option) uses
   %     significance level alpha (default 0.05). type is 'confidence'
   %     (default) for bounds on the fitted curve, or 'prediction' for
   %     bounds on new observations. Set option true for simultaneous
   %     bounds.
   %
   % See also: fitlm

   if nargin < 3 || isempty(alpha); alpha = 0.05; end
   if nargin < 4 || isempty(type); type = 'confidence'; end
   if nargin < 5 || isempty(option); option = false; end

   % type can be "confidence" or "prediction"
   % for "simultaneous", use option = true

   % Fit coefficients, covariance, mean square error, and residual degrees
   % of freedom. The quantiles use dfe, not numel(x), because x can differ
   % from the values used to fit the model.
   % Top row is intercept, bottom is slope. Pick the fields by the input
   % type, not the language: the Octave statistics package fitlm returns a
   % LinearModel, and older versions return the coeffs struct.
   if isfield(stats, 'coeffs')
      coeff = stats.coeffs(:, 1);
      Sigma = stats.vcov;
      mse = stats.mse;
      dfe = stats.dfe;
   else
      coeff = stats.Coefficients.Estimate;
      Sigma = stats.CoefficientCovariance;
      mse = stats.MSE;
      dfe = stats.DFE;
   end

   % Compute predicted values
   N = numel(x);
   X = [ones(N,1), x(:)];
   ypred = X * coeff; % ypred = coeff(1) + x.*coeff(2);

   % Compute confidence intervals
   if nargout > 1
      switch type
         case 'prediction' % prediction interval for new observations
            se = sqrt(sum((X*Sigma) .* X, 2) + mse);
         case 'confidence' % confidence interval for fitted curve
            se = sqrt(sum((X*Sigma) .* X, 2));
      end

      if option % simultaneous
         tval = sqrt(length(coeff) * finv(1-alpha, length(coeff), dfe));
      else
         tval = tinv(1-alpha/2, dfe);
      end
      delta = se * tval;
      yconf = [ypred-delta ypred+delta];
   end

   % Compute the standard error for each prediction
   % se = sqrt(mse .* (1 + 1/N + ((x - mean(x)).^2) ./ sum((x - mean(x)).^2)));

   % Plot the fit
   % figure;
   % plot(x, ypred); hold on;
   % plot(x, yconf, '--');

   % For reference:
   % sderr = stats.coeffs(:, 2);
   % confi = stats.coeffs(:, 3:4);
   % tstat = stats.coeffs(:, 5);
   % pvals = stats.coeffs(:, 6);
end

