function fdc = fdcurve(flow,varargin)
%FDCURVE Flow duration curve
%
%     fdc = fdcurve(flow,varargin)
%
% See also

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% parse inputs
[axscale, units, refpoints, plotcurve] = parseinputs(flow, varargin{:});

% main function

N = length(flow);
M = 1:N;
x = sort(flow,'descend');
f = 1-M./(N+1);

% if requested, compute reference point values
xref = nan(numel(refpoints,1));
fref = nan(numel(refpoints,1));
if ~isnan(refpoints)
   for n = 1:numel(refpoints)
      iref = find(x>=refpoints(n),1,'last');
      xref(n) = x(iref);
      fref(n) = f(iref);
   end
end

% plot the curve if requested
if plotcurve == true
   figure;
   switch axscale
      case 'loglog'
         h.fdc = loglog(100.*f,x); ax = gca;
      case 'semilogy'
         h.fdc = semilogy(100.*f,x); ax = gca;
      case 'semilogx'
         h.fdc = semilogx(100.*f,x); ax = gca;
      case 'linear'
         h.fdc = plot(100.*f,x); ax = gca;
   end

   % if requested, add a refpoint line
   if ~isnan(refpoints)
      hold on;
      for n = 1:numel(refpoints)
         xplot = [min(xlim) 100*fref(n) 100*fref(n) 100*fref(n)];
         yplot = [xref(n) xref(n) min(ylim) xref(n)];
         h.ref(n) = plot(xplot,yplot,'Color',[0.85 0.325 0.098],'LineWidth',1);
      end
   end

   ylabel(['$x$ [' units ']']);
   xlabel 'flow exceedence probability, $P(Q\ge x)$'

   ax.YAxis.TickLabels = compose('%g',ax.YAxis.TickValues);
   ax.XAxis.TickLabels = compose('$%g\\%%$',ax.XAxis.TickValues);

   % since i manually set the ticklabels, i think this is necessary
   % otherwise if the figure is resized, matlab will make new ticks
   set(gca,'XTickMode','manual','YTickMode','manual');

   fdc.h = h;
end

% package output
fdc.f = f;
fdc.x = x;
fdc.xref = xref;
fdc.fref = fref;

function [axscale, units, refpoints, plotcurve] = parseinputs(flow, varargin)

p = inputParser;
p.FunctionName = 'bfra.fdcurve';
p.addRequired( 'flow', @(x)isnumeric(x) );
p.addParameter('axscale', 'semilogy', @(x) ischar(x) );
p.addParameter('units', '', @(x) ischar(x) );
p.addParameter('refpoints', nan, @(x)isnumeric(x) );
p.addParameter('plotcurve', true, @(x)islogical(x) );
p.parse(flow, varargin{:});

refpoints = p.Results.refpoints;
plotcurve= p.Results.plotcurve;
axscale = p.Results.axscale;
units = p.Results.units;


% function [F,x] = ecdfpot(x,xmin,alpha,sigma)
%
%    % not implemented
%
%    % http://sfb649.wiwi.hu-berlin.de/fedc_homepage/xplore/tutorials/sfehtmlnode91.html
%
%    % peaks over threshold exceedance probability:
%    % F(x) = N(u)/n(1+gamma(x-u)/beta)^(-1/gamm),
%    % N(u) is the number of obs>u
%    % n is totla number, i think
%    % x would be tau
%    % u would be taumin
%    % gamma/beta would be b-1/tau0 i think
%    % so 1/gamm would be 1/b-1
%
%
%    N     = numel(x(x>xmin));
%    n     = numel(x);
%    gamma = b-1; % might be 1-b;
%    beta  = tau0;
%    F     = N/n.*(1+gamma.*(x-x0)/beta)^(-1/gamm);

