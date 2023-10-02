function [Fit,h] = fitphidist(phi,varargin)
   %FITPHIDIST fit drainable porosity (phi) values with a Beta distribution
   %
   % Syntax
   %
   %     FIT = baseflow.FITPHIDIST(phi);
   %     FIT = baseflow.FITPHIDIST(___,plottype);
   %     FIT = baseflow.FITPHIDIST(___,outputtype);
   %
   % Description
   %
   %     Fit = baseflow.fitphidist(phi) returns probability distribution object
   %     'Fit' which is a Beta Distribution fit to the input data in phi
   %
   %     Fit = baseflow.fitphidist(phi,outputtype) returns a Beta Distribution fit
   %     to the input data in phi. 'outputtype' is 'PD', 'mean', or 'std', where
   %     default 'PD' is the Probability Distribution object. 
   %
   %     Fit = baseflow.fitphidist(__,plottype) returns any of the prior options
   %     plus a figure showing the fit. plottype can be 'cdf' or 'pdf'. default
   %     is 'none'.
   %
   % See also: eventphi, fitphi, fitphidist
   %
   % Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [phi, outputtype, plottype, showfit] = parseinputs(phi, varargin{:});

   % Force all inputs to be column vectors
   phi = phi(:);

   % Fit the beta distribution
   [PARAMHAT, PARAMCI] = betafit(phi);
   [M, V] = betastat(PARAMHAT(1), PARAMHAT(2));
   PD.paramEst = PARAMHAT;
   PD.paramCI = PARAMCI;
   PD.a = PARAMHAT(1);
   PD.b = PARAMHAT(2);
   PD.mean = M;
   PD.std = sqrt(V);

   % Create the figure
   switch plottype
      case 'cdf'
         h = cdfplotphi(phi, PD, showfit);
      case 'probplot'
         h = probplotphi(phi, PD, showfit);
      case 'pdf'
   end

   % package output
   switch outputtype
      case 'PD'
         % send back the probability distribution
         Fit = PD;
      case 'mean'
         % send back the mean
         Fit = PD.mean;
      case 'std'
         % send back the mean
         Fit = PD.std;
   end
end

function h = cdfplotphi(phi, PD, showfit)

   % Get the cdf
   [cdfY, cdfX] = ecdf(phi, 'Function', 'cdf');
   
   % Create the figure
   h.figure = figure('Visible', showfit);
   h.data = plot(cdfX, cdfY, 'o', 'MarkerFaceColor', [0 0.447 0.741], ...
      'MarkerEdgeColor', 'none', 'Visible', showfit); hold on;

   % Create grid where function will be computed
   XLims = get(gca, 'XLim');
   XLims = XLims + [-1 1] * 0.01 * diff(XLims);
   XGrid = linspace(XLims(1), XLims(2), 100);

   % plot the cdf
   phifit = betacdf(XGrid, PD.a, PD.b);
   h.fit = plot(XGrid, phifit, 'k');
   set(gca, 'XLim', [0 max(phi)])

   % bootstrap standard error / CI's
   booterr = true;
   N = 1000;
   if booterr == true
      reps = bootstrp(N, @betafit, phi);
      mureps = reps(:, 1) ./ (sum(reps, 2));
      sigreps = sqrt(prod(reps, 2) ./ ((sum(reps, 2)+1) .* (sum(reps, 2)).^2));
   end

   % this slightly overestimates the error, which is fine (conservative)
   mu = mean(mureps);
   sg = mean(sigreps);
   pm = std(mureps) * 1.96; % or: mean(sigreps)/sqrt(N)*1.96

   if showfit == true && ~isoctave
      
      % compose legend text and arrow text
      ltxt = {'\phi', sprintf('Beta (\\alpha=%.2f,\\beta=%.1f)', PD.a, PD.b)};
      arrowtxt = sprintf('\\langle\\phi\\rangle=%.3f\\pm%.3f', mu, round(pm, 3));

      % add xlabel and legend
      xlabel('x');
      ylabel('P(\phi \leq x)', 'Interpreter', 'tex');
      
      xarrow = [PD.mean 1.3*PD.mean];
      yarrow = [betacdf(PD.mean, PD.a, PD.b) betacdf(PD.mean, PD.a, PD.b)];
      baseflow.deps.arrow([xarrow(2), yarrow(2)],[xarrow(1), yarrow(1)], ...
         'BaseAngle', 90, 'Length', 8, 'TipAngle', 10)
      text(0.95*xarrow(2), yarrow(2), arrowtxt, 'HorizontalAlignment','left')

      h.legend = legend(ltxt, 'Location', 'east', 'Interpreter', 'tex');
      h.legend.Position(2) = 0.68*h.legend.Position(2);
      h.legend.Position(1) = 0.85*h.legend.Position(1);
   end

   h.ax = gca;
   h.mu = mu;
   h.pm = pm;
end

function h = probplotphi(phi,PD)

   if isoctave
      error([mfilename ': probplot not implemented in Octave. Use ''cdf''.'])
   end

   % Create the figure
   h.figure = figure;

   % plot the data, suppressing the normal plot with 'noref'
   h.data = probplot('normal', phi, [], [], 'noref'); hold on;

   % add the fit
   h.fit = probplot(gca, PD);

   % format the symbols
   c  = [0 0.447 0.741];
   set(h.data, 'MarkerFaceColor', c, 'Marker', 'o', 'MarkerSize', 6, ...
      'MarkerEdgeColor', 'none');
   set(h.fit, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2);

   ylabel('P(\phi\leq x)', 'Interpreter', 'tex');
   title('')
   set(gca, 'XLim', [0 0.2])
   h.ax = gca;
end

%% INPUT PARSER
function [phi, outputtype, plottype, showfit] = parseinputs(phi, varargin)

   validoutput = @(x) any(validatestring(x, {'PD', 'mean', 'std'}));
   validplottype = @(x) any(validatestring(x, {'cdf', 'pdf', 'probplot'}));

   parser = inputParser;
   parser.FunctionName = 'baseflow.fitphidist';
   parser.addRequired('phi', @isvector);
   parser.addOptional('outputtype', 'PD', validoutput);
   parser.addOptional('plottype', 'none', validplottype);
   parser.addOptional('showfit', true, @islogical);
   parser.parse(phi, varargin{:});

   outputtype = parser.Results.outputtype;
   plottype = parser.Results.plottype;
   showfit = parser.Results.showfit;
end
