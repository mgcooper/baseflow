function [Fit,h] = bfra_fitdistphi(phi,varargin)
%BFRA_FITDISTPHI fits a Beta distribution to a sample of drainable porosity
%(phi) values 
% 
% Syntax:
% 
%  FIT = BFRA_FITDISTPHI(phi);
%  FIT = BFRA_FITDISTPHI(___,plottype);
%  FIT = BFRA_FITDISTPHI(___,outputtype);
% 
%  Fit = bfra_fitdistphi(phi) returns probability distribution object 'Fit'
%  which is a Beta Distribution fit to the input data in phi
% 
%  Fit = bfra_fitdistphi(phi,outputtype) returns a Beta Distribution fit to the
%  input data in phi. 'outputtype' is 'PD', 'mean', 'median', or 'std', where
%  default 'PD' is the Probability Distribution object.
% 
%  Fit = bfra_fitdistphi(__,plottype) returns any of the prior options plus a
%  figure showing the fit. plottype can be 'cdf' or 'pdf'. default is 'none'.
% 
% Author: Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'BFRA_FITDISTPHI';

addRequired(p,    'phi',                  @(x)isvector(x)            );
addOptional(p,    'outputtype',  'PD',    @(x)ischar(x)              );
addOptional(p,    'plottype',    'none',  @(x)ischar(x)              );

parse(p,phi,varargin{:});
outputtype = p.Results.outputtype;
plottype = p.Results.plottype;
%-------------------------------------------------------------------------------
   
   % Force all inputs to be column vectors
   phi = phi(:);
   
   % Fit the beta distribution
   PD = fitdist(phi, 'beta');

   % Create the figure
   switch plottype
      case 'cdf'
         h = bfra_cdfplotphi(phi,PD);
      case 'probplot'
         h = bfra_probplotphi(phi,PD);
      case 'pdf'   
   end
   
   % package output
   switch outputtype
      case 'PD'
         % send back the ProbabilityDistribution object
         Fit = PD;
      case 'mean'
         % send back the mean
         Fit = PD.mean;
      case 'std'
         % send back the mean
         Fit = PD.std;
      case 'median'
         Fit = PD.median;
   end
end

function h = bfra_cdfplotphi(phi,PD)
   
   % Create the figure
   h.figure = figure;
   
   % Get the cdf
   [cdfY,cdfX] = ecdf(phi,'Function','cdf');  % compute empirical function
%    h.data      = stairs(cdfX,cdfY,'LineWidth',1); hold on;

   c        = [0 0.447 0.741];
   h.data   = plot(cdfX,cdfY,'o','MarkerFaceColor',c,       ...
                  'MarkerEdgeColor','none'); hold on;
   
   % Create grid where function will be computed
   XLim     = get(gca,'XLim');
   XLim     = XLim + [-1 1] * 0.01 * diff(XLim);
   XGrid    = linspace(XLim(1),XLim(2),100);
   
   % plot the cdf
   phifit   = cdf(PD,XGrid);
   h.fit    = plot(XGrid,phifit,'k');
   
   set(gca,'XLim',[0 max(phi)])
   
   % bootstrap standard error / CI's 
   booterr  = true;
   N        = 1000;
   if booterr == true
      reps     = bootstrp(N,@betafit,phi);
      mureps   = reps(:,1)./(sum(reps,2));
      sigreps  = sqrt(prod(reps,2)./((sum(reps,2)+1).*(sum(reps,2)).^2));
   end
   
   % this slightly overestimates the error, whihc is fine (conservative)
   mu    = mean(mureps);
   sig   = mean(sigreps);
   pm    = std(mureps)*1.96; % or: mean(sigreps)/sqrt(N)*1.96

   % legend text and arrow text
   ltxt     = {'$\phi$',sprintf('Beta ($\\alpha=%.2f,\\beta=%.1f)$',PD.a,PD.b)};
   arrowtxt = sprintf('$\\langle\\phi\\rangle=%.3f\\pm%.3f$',mu,round(pm,2));
%  arrowtxt = sprintf('$\\langle\\phi\\rangle=%.3f\\pm%.3f$',PD.mean,PD.std);
   
   % add xlabel and legend
   %xlabel('$\phi$');
   xlabel('$x$');
   ylabel('$P(\phi\le x)$'); 
   
   % add an arrrow pointing to the expected value
   xarrow   = [PD.mean 1.3*PD.mean];
   yarrow   = [PD.cdf(PD.mean) PD.cdf(PD.mean)];
   [X1,Y1]  = ds2nfu(xarrow(1),yarrow(1));
   [X2,Y2]  = ds2nfu(xarrow(2),yarrow(2));
   
   annotation(gcf,'textarrow',[1.06*X2 1.025*X1],[Y2 Y1],                     ...
            'String',{arrowtxt}, ...
            'HeadStyle','plain','HeadLength',4,   ...
            'HeadWidth',2,'LineWidth',1,'Interpreter','latex');
         
   h.ff = figformat;
   h.legend = legend(ltxt,'Location','east','Interpreter','latex');
   h.legend.Position(2) = 0.68*h.legend.Position(2);
   h.legend.Position(1) = 0.85*h.legend.Position(1);
   
   h.ax  = gca;
   h.mu  = mu;
   h.pm  = pm;
end

function h = bfra_probplotphi(phi,PD);
   
   % Create the figure
   h.figure = figure;
   
   % plot the data, suppressing the normal plot with 'noref'
   h.data      = probplot('normal',phi,[],[],'noref'); hold on;

   % add the fit
   h.fit       = probplot(gca,PD);
   
   % format the symbols
  %c  = [0.33 0 0.67];
   c  = [0 0.447 0.741];
   set(h.data,'MarkerFaceColor',c,'Marker','o','MarkerSize',6,'MarkerEdgeColor','none');
   set(h.fit,'Color','k','LineStyle','-', 'LineWidth',2);

   ylabel('$P(\phi\le x)$'); 
%    ylabel('Probability')
   title('')
   set(gca,'XLim',[0 0.2])
   
   h.ax  = gca;
end