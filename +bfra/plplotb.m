function h = plplotb(x,xmin,alpha,varargin)
%PLPLOTB plot the power law fit to the P(tau) pareto distribution
%
% Required inputs
% 
%     x     = vector double of data believed to follow a Pareto distribution 
%     xmin  = scalar double indicating the lower bound of the distribution
%     alpha = scalar double indicating the exponent of the distribution
%
% Optional inputs
% 
%     alphaci  = 2x1 double of lower and upper confidence intervals for alpha
%     xminci   = 2x1 double of lower and upper confidence intervals for xmin
%     varsym   = char in latex format representing the data symbol, used for plot
%     trimline = logical scalar indicating whether to 'trim' the fitted line
%                 similar to 'axis tight' option (b/c power law data is often
%                 covering many orders of magnitude)
%     labelplot = logical scalar indicating whether to add a label showing the
%                 value of xmin and the expected value of x
%     ax       =  graphic axis to plot into
% 
% See also: plfit, plfitb, gpfitb, eventtau 
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% PARSE INPUTS
[x, xmin, alpha, alphaci, xminci, varsym, trimline, labelplot, ax] = ...
   parseinputs(x, xmin, alpha, varargin{:});
   
% Compute the complementary cumulative distribution function
N = numel(x);
xccp = sort(x);
yccp = (N:-1:1)'./N;
refy = yccp(find(xccp>=xmin,1,'first'));

% Option to extend the line forward a bit (purely aesthetic)
if trimline == true
   xccfit = sort(x(x>=xmin));
   xccfit = [xccfit; xccfit(end)*1.2];
else
   xccfit = sort(x); % this extends the line back toward the origin
   xccfit = [xccfit; xccfit(end)*1.2]; % this extends the line forward a bit
end

% Compute the theoretical ccdf
yccfit = (xccfit./xmin).^(1-alpha);

% scale the fitted x>xmin ccdf to pass through the refPoint
yccfit = yccfit.*refy; 
xccfit = xccfit(yccfit<=1);
yccfit = yccfit(yccfit<=1);

% plot it
h.data = loglog(ax,xccp,yccp,'o','LineWidth',0.5,'MarkerSize',10, ...
   'MarkerFaceColor','w'); hold on;
h.fit = loglog(ax,xccfit,yccfit,'LineWidth',3);

% compute b for the legend
b = bfra.conversions(alpha,'alpha','b');

% build a legend, labels, etc.
l1 = ['$' varsym '$ (data)'];
if ~isnan(alphaci)
   bL = bfra.conversions(alphaci(1),'alpha','b');
   bH = bfra.conversions(alphaci(2),'alpha','b');
   l2 = sprintf('MLE fit ($\\hat{b}=%.2f\\ [$%.2f,%.2f$]\\ 95\\%%$ CI)',b,bL,bH);
else
   l2 = sprintf('MLE fit ($b=%.2f$)',bfra.conversions(alpha,'alpha','b'));
   bL = nan;
   bH = nan;
end

xtext = '$x$';
ytext = ['$p(' varsym '\ge x)$'];

if bfra.util.isoctave
   l1 = bfra.util.latex2tex(l1);
   l2 = sprintf('MLE fit (b=%.2f [%.2f,%.2f] 95%% CI)',b,bL,bH);
   xlabel(bfra.util.latex2tex(xtext),'Interpreter','tex'); 
   ylabel(bfra.util.latex2tex(ytext),'Interpreter','tex'); 
   h.legend = legend({l1,l2},'interpreter','tex','location','southwest');
else
   xlabel(xtext,'Interpreter','latex');
   ylabel(ytext,'Interpreter','latex'); 
   h.legend = legend({l1,l2},'interpreter','latex','location','southwest');
end

% h.legend.Position = [0.27 0.40 0.30 0.10];

if ~isnan(xminci)
   xminL = xminci(1);
   xminH = xminci(2);
else
   xminL = xmin;
   xminH = xmin;
end

if labelplot == true
   %addlabels(xccfit,ccfit,xmin,xminL,xminH,b,bL,bH,refy);
   addlabels(xccfit,yccfit,xmin,xminL,xminH,b);
end

% add a little white space above P=1
h.ax = gca;
ylimits = get(ax, 'YLim');
ylimits(2) = 1.5;
set(h.ax, 'YLim', ylimits); 

%% LOCAL FUNCTIONS
function addlabels(xfit,yfit,tau0,tau0L,tau0H,b)
%ADDLABELS add an arrow pointing to tau0 and tau_exp

% 'arrow' is not octave compatible afaik
if bfra.util.isoctave
   return 
end

% tau0
xminc = (tau0H-tau0+tau0-tau0L)/2;
xlims = xlim;
ndecx = log10(xlims(2))-log10(xlims(1));
xarrw = [10^(log10(tau0)-ndecx/10) tau0];
yarrw = yfit(find(xfit>=xarrw(1),1,'first'));
yarrw = [yarrw yarrw];

% build the string with plus/minus if tau0L/H is provided
if tau0==tau0L && tau0==tau0H
   ta = sprintf('$\\hat{\\tau}_0=%.0f$ days',tau0);
else
   ta = sprintf('$\\hat{\\tau}_0=%.0f\\pm%.0f$ days',tau0,xminc);
end

% draw the arrow
bfra.deps.arrow([xarrw(1),yarrw(1)],[xarrw(2),yarrw(2)], ...
   'BaseAngle',90,'Length',8,'TipAngle',10)
text(0.95*xarrw(1),yarrw(1),ta, ...
   'HorizontalAlignment','right','FontSize',14,'Interpreter','latex')

% % tauExp
%----------------------------------------------------------------------------
% test using the new xminL/H
% deactivate this and reactive the two lines below to go back 
xexp = tau0*(2-b)/(3-2*b);
tauL = tau0L*(2-b)/(3-2*b);
tauH = tau0H*(2-b)/(3-2*b);
xexpc = (tauH-tauL)/2;
% xexp  = mean((tau0*(2-bL)/(3-2*bL) + tau0*(2-bH)/(3-2*bH))/2);
% xexpc = mean(abs(xexp-[tau0*(2-bL)/(3-2*bL), tau0*(2-bH)/(3-2*bH)]));
%----------------------------------------------------------------------------

xarrw = [10^(log10(xexp)-ndecx/10) xexp];
yarrw = yfit(find(xfit>=xarrw(2),1,'first'));
yarrw = [yarrw yarrw];

% build the string with plus/minus if tau0L/H is provided
if tau0==tau0L && tau0==tau0H
   ta = sprintf('$\\langle\\tau\\rangle=%.0f$ days',xexp);
else
   ta = sprintf('$\\langle\\tau\\rangle=%.0f\\pm%.0f$ days',xexp,xexpc);
end

bfra.deps.arrow([xarrw(1),yarrw(1)],[xarrw(2),yarrw(2)], ...
   'BaseAngle',90,'Length',8,'TipAngle',10)
text(0.95*xarrw(1),yarrw(1),ta, ...
   'HorizontalAlignment','right','FontSize',14,'Interpreter','latex')

%% INPUT PARSER
function [x, xmin, alpha, alphaci, xminci, varsym, trimline, labelplot, ax] = ...
   parseinputs(x, xmin, alpha, varargin)
parser = inputParser;
parser.FunctionName = 'bfra.plplotb';
parser.CaseSensitive = false;
parser.KeepUnmatched = true;

parser.addRequired('x', @isnumeric);
parser.addRequired('xmin', @isnumeric);
parser.addRequired('alpha', @isnumeric);
parser.addParameter('alphaci', nan, @isnumeric);
parser.addParameter('xminci', nan, @isnumeric);
parser.addParameter('varsym', '\tau', @ischar);
parser.addParameter('trimline', false, @islogical);
parser.addParameter('labelplot', true, @islogical);
parser.addParameter('ax', gca, @(x)bfra.validation.isaxis(x));

parser.parse(x, xmin, alpha, varargin{:});

alphaci     = parser.Results.alphaci;
xminci      = parser.Results.xminci;
varsym      = parser.Results.varsym;
trimline    = parser.Results.trimline;
labelplot   = parser.Results.labelplot;
ax          = parser.Results.ax;
