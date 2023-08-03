function [href,ab] = plotrefline(x,y,varargin)
%PLOTREFLINE add a reference line to a point cloud plot
%
% Syntax
%
%     [href,ab] = plotrefline(x,y,varargin)
%
% Required inputs
%
%     x  = vector of type double (nominally discharge q)
%     y  = vector of type double (nominally discharge rate of change -dq/dt)
%
% Optional name-value inputs
%
%     mask     =  vector logical mask to exclude values from fitting
%     refline  =  char indicating what type of refline to plot
%     refslope =  scalar double indicating a user-defined slope
%     userab   =  2x1 double indicating a user-defined intercept,slope pair
%     labels   =  logical indicating whether to add labels
%     refqtls  =  2x1 double, x/y quantiles used if 'method' == 'envelope'
%     plotline =  logical indicating whether to add the line plot (for some cases
%                 this function can be used to return the a/b values only)
%     linecolor = rgb triplet indicating the line color
%     precision = scalar double indicating the precision in the x data, used to
%                 compute the 'lower envelope'
%     timestep  = scalar double indicating the timestep of the x data, used to
%                 compute the 'lower envelope'
%     ax       =  graphic axis to plot into
%
% See also fitab, pointcloudintercept, pointcloudplot
%
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% NOTE: y comes in as -dq/dt, send it to bfra.fitab as -y, and to refline as y

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% PARSE INPUTS
[x, y, mask, refline, refslope, userab, labels, refqtls, plotline, ...
   linecolor, precision, timestep, ax] = parseinputs(x, y, varargin{:});

% need options for how/if to apply the mask - e.g., we might want to show the
% 'bestfit' to all data, and use the mask for late-time fit. also keep in mind
% bfra.eventphi calls this. mask is default true in parsing.

% use this to find the equation of the line
axb = @(a,x,b) a.*x.^b;

% keep track of the original axis limits
if plotline == true
   if isempty(ax)
      ax = gca;
   end
   hold on;
   xlims = get(ax,'XLim');
   ylims = get(ax,'YLim');
end

switch refline

   case 'upperenvelope'
      b = 1;               % slope = 1
      a = 2/timestep;      % for daily, intercept = 2
   case 'lowerenvelope'
      b = 0;                           % slope = 0 unless stage precision is known
      a = precision*3600*24/timestep;  % 1 m3/s converted to m3/timestep with timestep in days
   case 'linear'
      F = bfra.fitab(x(mask),-y(mask),'ols','order',1);
      a = F.ab(1);
      b = F.ab(2);
   case 'bestfit'
      F = bfra.fitab(x(mask),-y(mask),'nls');
      a = F.ab(1);
      b = F.ab(2);
   case 'userfit'
      a = userab(1);
      b = userab(2);
   case 'envelope'
      F = bfra.fitab(x(mask),-y(mask),'envelope','refqtls',refqtls,'order',refslope);
      a = F.ab(1);
      b = F.ab(2);
   case 'earlytime'
      if refslope == 1; refslope = 3; end
      F = bfra.fitab(x,-y,'envelope','refqtls',[0.95 0.95],'order',refslope);
      a = F.ab(1);
      b = F.ab(2);
   case 'latetime'
      F = bfra.fitab(x(mask),-y(mask),'envelope','refqtls',[0.5 0.5],'order',refslope);
      a = F.ab(1);
      b = F.ab(2);
   otherwise
      % use upper envelope
      b = 1;               % slope = 1
      a = 2/timestep;      % for daily, intercept = 2
end

% send back the ab
href = [];                 % this gets sent back in case plotline false
ab = [a;b];

% Below here only needed if plot is requested
if plotline == true

   xref = linspace(xlims(1),xlims(2),100);
   yref = axb(a,xref,b);

   switch refline
      case 'bestfit'
         href = loglog(xref,yref,':','LineWidth',1,'Color',linecolor);
      case 'userfit'
         href = loglog(xref,yref,'-','LineWidth',1,'Color',linecolor);
      otherwise
         href = loglog(xref,yref,'-','LineWidth',0.5,'Color',linecolor);
   end

   % reset the x,ylims
   set(ax,'XLim',xlims,'YLim',ylims,'TickLabelInterpreter','tex')
   bfra.util.setlogticks(ax);

   if labels == true
      addlabels(a,b,refline)
   end

end

% if discharge were measured directly, then the lower envelope would be
% the precision of the measurements, here I assume that it is 1 m3/s, and
% this lower envelope would appear as a horizontal line, also at
% integer multiples of it.

%% LOCAL FUNCTIONS

function addlabels(a,b,refline)

% for early and late, we use the early-time form to get the y position
ylims = ylim;
xlims = xlim;

% use the number of decades to place the labels
ndecsy = log10(ylims(2))-log10(ylims(1));
ndecsx = log10(xlims(2))-log10(xlims(1));

% place the label 1/2 way b/w the first and second decade
ya = 10^(log10(ylims(1))+ndecsy/20);

switch refline

   %case {'latetime','earlytime','userfit','bestfit'}
   case {'latetime','earlytime','userfit'}
      xa = (ya/a)^(1/b);

      % make the arrow span 1/10th or so of the total number of decades
      xa = [xa 10^(log10(xa)+ndecsx/15)];

      ya = [ya ya];

      if strcmp(refline, 'userfit')
         ta = sprintf('$b=%.2f$ ($\\hat{b}$)',b);
      elseif b==1 || b==3
         ta = sprintf('$b=%.0f$',b);
      elseif b==3/2
         ta = sprintf('$b=%.1f$',b);
      else
         ta = sprintf('$b=%.2f$',b);
      end

      if ~bfra.util.isoctave
         bfra.deps.arrow([xa(2),ya(2)],[xa(1),ya(1)], ...
            'BaseAngle',90,'Length',8,'TipAngle',10);
         text(1.03*xa(2),ya(2),ta,'HorizontalAlignment','left', ...
            'fontsize',13,'Interpreter','latex');
      end

   case 'upperenvelope'

      axpos = bfra.deps.plotboxpos(gca); % only works with correct axes position
      % xtxt = exp(mean(log(xlim)));

      xlims = log10(xlim);
      xtxt = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
      ytxt = 2*xtxt;
      rtxt = 0.98;

      % some values of rtxt that work for different types of plots
      % 5.1    bfra_checkevent2 figure (I used 5.22 in the final fig)
      % 0.22   not sure (note said 0.22 works with tiledlayout)
      % 3.8    not sure (note said i think 3.8 works with subplot)
      % 0.86   the standard point cloud plot (standard figure size)
      % 1.07   not sure but this was
      % 0.98   used this in the final point cloud plot

      bfra.util.rotatedLogLogText(xtxt,ytxt,'upper envelope',rtxt,axpos,'FontSize',11);

   case 'lowerenvelope'
      % for now, add this after the fact
      %
      %          xlims    = log10(xlim);
      %          xtxt     = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
      %          ytxt     = 2*xtxt;

end

%% INPUT PARSER
function [x, y, mask, refline, refslope, userab, labels, refqtls, plotline, ...
   linecolor, precision, timestep, ax] = parseinputs(x, y, varargin)
parser = inputParser;
parser.FunctionName = 'bfra.plotrefline';

parser.addRequired('x', @isnumeric);
parser.addRequired('y', @isnumeric);
parser.addParameter('mask', true(size(x)), @islogical);
parser.addParameter('refline', 'none', @ischar);
parser.addParameter('refslope', 1, @isnumeric);
parser.addParameter('userab', [1 1], @isnumeric);
parser.addParameter('labels', false, @islogical);
parser.addParameter('refqtls', nan, @isnumeric);
parser.addParameter('plotline', true, @islogical);
parser.addParameter('linecolor', [0 0 0], @isnumeric);
parser.addParameter('precision', 1, @isnumeric); % default = 1 m3/s
parser.addParameter('timestep', 1, @isnumeric); % default = 1 day
parser.addParameter('ax', bfra.util.emptyaxes, @bfra.validation.isaxis);

parser.parse(x, y, varargin{:});

mask        = parser.Results.mask;
refline     = parser.Results.refline;
refslope    = parser.Results.refslope;
userab      = parser.Results.userab;
labels      = parser.Results.labels;
refqtls     = parser.Results.refqtls;
plotline    = parser.Results.plotline;
linecolor   = parser.Results.linecolor;
precision   = parser.Results.precision;
timestep    = parser.Results.timestep;
ax          = parser.Results.ax;


