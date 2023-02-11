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

%-------------------------------------------------------------------------------
p               = inputParser;
p.FunctionName  = 'bfra.plplotb';
p.CaseSensitive = false;
p.KeepUnmatched = true;

addRequired(   p, 'x',                          @(x)isnumeric(x)     );
addRequired(   p, 'xmin',                       @(x)isnumeric(x)     );
addRequired(   p, 'alpha',                      @(x)isnumeric(x)     );
addParameter(  p, 'alphaci',        nan,        @(x)isnumeric(x)     );
addParameter(  p, 'xminci',         nan,        @(x)isnumeric(x)     );
addParameter(  p, 'varsym',         '\tau',     @(x)ischar(x)        );
addParameter(  p, 'trimline',       false,      @(x)islogical(x)     );
addParameter(  p, 'labelplot',      true,       @(x)islogical(x)     );
addParameter(  p, 'ax',             gca,        @(x)isaxis(x)        );

parse(p,x,xmin,alpha,varargin{:});

alphaci     = p.Results.alphaci;
xminci      = p.Results.xminci;
varsym      = p.Results.varsym;
trimline    = p.Results.trimline;
labelplot   = p.Results.labelplot;
ax          = p.Results.ax;
%-------------------------------------------------------------------------------
   
% get the complementary cumulative distribution function
numData     =  numel(x);
xccp        =  sort(x);
ccp         =  (numData:-1:1)'./numData;
refy        =  ccp(find(xccp>=xmin,1,'first'));

% option to extend the line forward a bit (purely aesthetic)
if trimline == true
   xccfit   =  sort(x(x>=xmin));
   xccfit   =  [xccfit; xccfit(end)*1.2];
else
   xccfit   =  sort(x); % this extends the line back toward the origin
   xccfit   =  [xccfit; xccfit(end)*1.2]; % this extends the line forward a bit
end

% compute the ccdf
ccfit       =  (xccfit./xmin).^(1-alpha);

% scale the fitted x>xmin ccdf to pass through the refPoint
ccfit       =  ccfit.*refy; 
xccfit      =  xccfit(ccfit<=1);
ccfit       =  ccfit(ccfit<=1);

% plot it
h.data = loglog(ax,xccp,ccp,'o','LineWidth',0.5,'MarkerSize',10, ...
   'MarkerFaceColor','w'); hold on;
h.fit = loglog(ax,xccfit,ccfit,'LineWidth',3);

% compute b for the legend
b = bfra.conversions(alpha,'alpha','b');

% build a legend, labels, etc.
ltxt1    = ['$' varsym '$ (data)'];
if ~isnan(alphaci)
   bL    = bfra.conversions(alphaci(1),'alpha','b');
   bH    = bfra.conversions(alphaci(2),'alpha','b');
   ltxt2 = sprintf('MLE fit ($\\hat{b}=%.2f\\ [$%.2f,%.2f$]\\ 95\\%%$ CI)',b,bL,bH);
else
   ltxt2 = sprintf('MLE fit ($b=%.2f$)',bfra.conversions(alpha,'alpha','b'));
   bL = nan;
   bH = nan;
end
xlabel('$x$');
ylabel(['$p(' varsym '\ge x)$'],'Interpreter','latex'); 
h.legend = legend(ltxt1,ltxt2,'interpreter','latex','location','sw');

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
   addlabels(xccfit,ccfit,xmin,xminL,xminH,b);
end

h.ax = gca;
h.ax.YLim(2)  = 1.5; % add a little white space above P=1


function addlabels(xfit,yfit,tau0,tau0L,tau0H,b)

% tau0
xminc = (tau0H-tau0+tau0-tau0L)/2;
xlims = xlim;
ndecx = log10(xlims(2))-log10(xlims(1));
xa    = [10^(log10(tau0)-ndecx/10) tau0];

ya    = yfit(find(xfit>=xa(1),1,'first'));
ya    = [ya ya];

% build the string with plus/minus if tau0L/H is provided
if tau0==tau0L && tau0==tau0H
   ta = sprintf('$\\hat{\\tau}_0=%.0f$ days',tau0);
else
   ta = sprintf('$\\hat{\\tau}_0=%.0f\\pm%.0f$ days',tau0,xminc);
end

arrow([xa(1),ya(1)],[xa(2),ya(2)],'BaseAngle',90,'Length',8,'TipAngle',10)
text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right','FontSize',14)


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

xa    = [10^(log10(xexp)-ndecx/10) xexp];
ya    = yfit(find(xfit>=xa(2),1,'first'));
ya    = [ya ya];

% build the string with plus/minus if tau0L/H is provided
if tau0==tau0L && tau0==tau0H
   ta = sprintf('$\\langle\\tau\\rangle=%.0f$ days',xexp);
else
   ta = sprintf('$\\langle\\tau\\rangle=%.0f\\pm%.0f$ days',xexp,xexpc);
end

arrow([xa(1),ya(1)],[xa(2),ya(2)],'BaseAngle',90,'Length',8,'TipAngle',10)
text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right','FontSize',14)

