function [Fit,h] = fitphidist(phi,varargin)
%FITPHIDIST fit drainable porosity (phi) values with a Beta distribution
% 
% Syntax
% 
%     FIT = bfra.FITPHIDIST(phi);
%     FIT = bfra.FITPHIDIST(___,plottype);
%     FIT = bfra.FITPHIDIST(___,outputtype);
% 
% Description
% 
%     Fit = bfra.fitphidist(phi) returns probability distribution object 'Fit'
%     which is a Beta Distribution fit to the input data in phi
% 
%     Fit = bfra.fitphidist(phi,outputtype) returns a Beta Distribution fit to
%     the input data in phi. 'outputtype' is 'PD', 'mean', 'median', or 'std',
%     where default 'PD' is the Probability Distribution object.
% 
%     Fit = bfra.fitphidist(__,plottype) returns any of the prior options plus a
%     figure showing the fit. plottype can be 'cdf' or 'pdf'. default is 'none'.
% 
% See also eventphi, fitphi, fitphidist
% 
% Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'fitphidist';

validoutput       = @(x) any(validatestring(x,{'PD','mean','std','median'}));
validplottype     = @(x) any(validatestring(x,{'cdf','pdf','probplot'}));

addRequired(p,    'phi',                  @(x)isvector(x)            );
addOptional(p,    'outputtype',  'PD',    validoutput                );
addOptional(p,    'plottype',    'none',  validplottype              );
addOptional(p,    'showfit',     true,    @(x)islogical(x)           );

parse(p,phi,varargin{:});
outputtype  = p.Results.outputtype;
plottype    = p.Results.plottype;
showfit     = p.Results.showfit;

%-------------------------------------------------------------------------------
   
% Force all inputs to be column vectors
phi = phi(:);

% Fit the beta distribution
PD = fitdist(phi, 'beta');

% Create the figure
switch plottype
   case 'cdf'
      h = cdfplotphi(phi,PD,showfit);
   case 'probplot'
      h = probplotphi(phi,PD,showfit);
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


function h = cdfplotphi(phi,PD,showfit)
   
% Create the figure
h.figure = figure('Visible',showfit);

% Get the cdf
[cdfY,cdfX] = ecdf(phi,'Function','cdf');  % compute empirical function
%    h.data      = stairs(cdfX,cdfY,'LineWidth',1); hold on;

c        = [0 0.447 0.741];

h.data   = plot(cdfX,cdfY,'o','MarkerFaceColor',c,       ...
               'MarkerEdgeColor','none','Visible',showfit); hold on;

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

if showfit == true
   % legend text and arrow text
   ltxt     = {'$\phi$',sprintf('Beta ($\\alpha=%.2f,\\beta=%.1f)$',PD.a,PD.b)};
   arrowtxt = sprintf('$\\langle\\phi\\rangle=%.3f\\pm%.3f$',mu,round(pm,3));
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
end

h.ax  = gca;
h.mu  = mu;
h.pm  = pm;


function h = probplotphi(phi,PD)
   
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
