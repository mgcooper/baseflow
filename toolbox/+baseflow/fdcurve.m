function fdc = fdcurve(flow,varargin)
   %FDCURVE Compute a flow duration curve from streamflow timeseries.
   %
   %     fdc = fdcurve(flow,varargin)
   %
   %     fdc.f is the non-exceedance position 1 - M/(N+1) of each flow in
   %     fdc.x, which is sorted largest first. M counts the flows at or above
   %     that flow, and N counts the flows that are not missing. fdc.fref and
   %     fdc.xref hold one value for each 'refpoints' value, NaN for a NaN
   %     point or a point above every flow.
   %
   % See also: hyetograph

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % parse inputs
   [axscale, units, refpoints, plotfit] = parseinputs(flow, varargin{:});

   % main function

   % a missing flow has no rank, so it stays out of the plotting positions
   flow = flow(~isnan(flow));
   N = length(flow);
   M = 1:N;
   x = sort(flow,'descend');
   f = 1-M./(N+1);

   % if requested, compute reference point values. x is sorted descending,
   % so the count of flows at or above a point is the index of the last one.
   % A nan point, or one above every flow, has no index and stays nan.
   xref = nan(size(refpoints));
   fref = nan(size(refpoints));
   iref = sum(x(:)>=refpoints(:).',1);
   xref(iref>0) = x(iref(iref>0));
   fref(iref>0) = f(iref(iref>0));

   % plot the curve if requested
   if plotfit == true
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
      xlabel 'flow non-exceedance probability, $P(Q<x)$'

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
end

function [axscale, units, refpoints, plotfit] = parseinputs(flow, varargin)

   p = inputParser;
   p.FunctionName = 'baseflow.fdcurve';
   p.addRequired( 'flow', @isnumeric);
   p.addParameter('axscale', 'semilogy', @ischar);
   p.addParameter('units', '', @ischar);
   p.addParameter('refpoints', nan, @isnumeric);
   p.addParameter('plotfit', true, @islogical);
   p.parse(flow, varargin{:});

   refpoints = p.Results.refpoints;
   plotfit= p.Results.plotfit;
   axscale = p.Results.axscale;
   units = p.Results.units;
end

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

