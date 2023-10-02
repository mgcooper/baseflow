function [ypred, yconf] = predictlm(stats, x, alpha, type, option)

   if nargin < 3 || isempty(alpha); alpha = 0.05; end
   if nargin < 4 || isempty(type); type = 'confidence'; end
   if nargin < 5 || isempty(option); option = false; end

   % type can be "confidence" or "prediction"
   % for "simultaneous", use option = true

   % Fit coefficients, covariance, and mean square error.
   % Top row is intercept, bottom is slope
   if isoctave
      coeff = stats.coeffs(:, 1);
      Sigma = stats.vcov;
      mse = stats.mse;
   else
      coeff = stats.Coefficients.Estimate;
      Sigma = stats.CoefficientCovariance;
      mse = stats.MSE;
      % dfe = stats.DFE;
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
         tval = sqrt(length(coeff) * finv(1-alpha, length(coeff), N-2));
      else
         tval = tinv(1-alpha/2, N-2);
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

