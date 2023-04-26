function plotComparisonResults(t, Q, dQdt, fitResults)
% Plot the comparison results of the error models for -dQ/dt = aQ^b fitting.

% Define the model function
modelFun = @(params, Q) params(1) * Q.^params(2);

% Plot the data and fitted models on linear and log-log axes
figure;
for n = 1:2
   if n == 1
      subplot(1, 2, 1); % linear axes
      plotType = 'linear';
   else
      subplot(1, 2, 2); % log-log axes
      plotType = 'log';
   end

   % Plot the observed data
   scatter(Q, dQdt, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'b');
   set(gca, 'XScale', plotType, 'YScale', plotType);
   hold on;

   % Plot the fitted models
   legendEntries = cell(1, height(fitResults) + 1);
   legendEntries{1} = 'Observed data';

   for m = 1:height(fitResults)
      params = [fitResults.a(m) fitResults.b(m)];
      fittedValues = modelFun(params, Q);

      [sortedFlow, idx] = sort(Q);
      plot(sortedFlow, fittedValues(idx), 'LineWidth', 2);

      legendEntries{m + 1} = sprintf('Fitted model (%s, R^2=%.2f)', ...
         fitResults.ErrorModel(m), fitResults.Rsquared(m));
   end

   % Add legend, labels, and title
   legend(legendEntries, 'Location', 'best');
   xlabel('Q');
   ylabel('-dQ/dt');
   title(['Best model: ', ...
      char(fitResults.ErrorModel(find(min(fitResults.AIC)==fitResults.AIC, 1)))]);

   hold off;
end

% % Display fit statistics for each model in a table
% for n = 1:height(fitResults)
%    disp(fitResults.ErrorModel(n));
%    disp(fitResults.RMSE(n));
% end

end
