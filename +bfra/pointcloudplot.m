function out = pointcloudplot(q,dqdt,varargin)
%POINTCLOUDPLOT plot a point-cloud diagram to estimate aquifer parameters
%
% Syntax
% 
%     out = pointcloudplot(q,dqdt,varargin) 
% 
% Required inputs
% 
%     q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%     dqdt        =  discharge rate of change (L T^-2)
%
% Optional name-value inputs
% 
%     mask        =  vector logical mask to exclude values from fitting
%     reflines    =  cell array of chars indicating what type of reflines to plot
%     reflabels   =  logical indicating whether to add labels
%     blate       =  late-time b parameter in -dqdt = aq^b (dimensionless)
%     userab      =  2x1 double indicating a user-defined intercept,slope pair
%     precision   =  scalar double indicating the precision in the x data, used to
%                    compute the 'lower envelope'
%     timestep    =  scalar double indicating the timestep of the x data, used to
%                    compute the 'lower envelope'
%     addlegend   =  logical indicating whether to add a legend or not
%     usertext    =  char that gets added to the legend if refline 'userfit' (to
%                    indicate what is being plotted, maybe a custom user model)
%     rain        =  vector double of rainfall (mm/time)
%     ax          =  graphic axis to plot into
% 
% See also fitab, plotdqdt
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.pointcloudplot';

addRequired(p, 'q',                             @(x)isnumeric(x));
addRequired(p, 'dqdt',                          @(x)isnumeric(x));
addParameter(p,'mask',        true(size(q)),    @(x)islogical(x));
addParameter(p,'reflines',    {'bestfit'},      @(x)iscell(x));
addParameter(p,'reflabels',   false,            @(x)bfra.validation.islogicalscalar(x));
addParameter(p,'blate',       1,                @(x)isnumeric(x));
addParameter(p,'userab',      [1 1],            @(x)isnumeric(x));
addParameter(p,'precision',   1,                @(x)isnumeric(x));
addParameter(p,'timestep',    1,                @(x)isnumeric(x));
addParameter(p,'addlegend',   true,             @(x)islogical(x));
addParameter(p,'usertext',    '',               @(x)ischar(x));
addParameter(p,'rain',        nan,              @(x)isnumeric(x));
addParameter(p,'ax',          'none',           @(x)bfra.validation.isaxis(x)|ischar(x));

parse(p,q,dqdt,varargin{:});

mask        = p.Results.mask;
reflines    = p.Results.reflines;
reflabels   = p.Results.reflabels;
blate       = p.Results.blate;
userab      = p.Results.userab;
precision   = p.Results.precision;
timestep    = p.Results.timestep;
addlegend   = p.Results.addlegend;
usertext    = p.Results.usertext;
rain        = p.Results.rain;
ax          = p.Results.ax;

% Note: ab is for 'reflines','userfit' so a pre-computed ab can be plotted
%-------------------------------------------------------------------------------
   
if not(bfra.validation.isaxis(ax))
   fig = figure('Position',[380 200 300 210]); ax = gca;
   %fig = figure('Position',[380 200 550 510]); ax = gca;
   %fig = figure('Units','centimeters','Position',[5 5 23*4/5 19*4/5]); ax = gca;
else
   fig = get(ax,'Parent');
end

h0 = loglog(ax,q,-dqdt,'o'); 
bfra.util.formatPlotMarkers('markersize',6); 
hold on; grid off;

% add circles around the t>tau0 values if requested
if sum(mask) < numel(q)
   h1 = scatter(q(mask),-dqdt(mask),'r');
else
   h1 = [];
end

% add some space around the data
xlims    = xlim;
ylims    = ylim;
ylowlim  = min(ylims);
yupplim  = max(ylims);

xlim([xlims(1)*.9 xlims(2)*1.1]);
% xlim([xlims(1)/(log10(xlims(2))-log10(xlims(1))) *.09 xlims(2)*1.1]);

% set xylabels
xlabel(bfra.getstring('Q','units',true),'FontSize',14);
ylabel(bfra.getstring('dQdt','units',true),'FontSize',14);

% init containers
h  = gobjects(numel(reflines),1);
ab = nan(numel(reflines),2);


% add reflines
for n = 1:numel(reflines)

   switch reflines{n}

      case 'early'
         [h(n),ab(n,:)] =  bfra.plotrefline(             ...
                           q,-dqdt,                      ...
                           'refline','earlytime',        ...
                           'refslope',3,                 ...
                           'labels',reflabels,           ...
                           'mask',mask                   ...
                           );

         h(n).LineWidth = 1;

      case 'late'
         [h(n),ab(n,:)] =  bfra.plotrefline(             ...
                           q,-dqdt,                      ...
                           'refline','latetime',         ...
                           'refslope',blate,             ...
                           'labels',reflabels,           ...
                           'mask',mask                   ...
                           );

         h(n).LineWidth = 1;

      case 'upperenvelope'
         [h(n),ab(n,:)] =  bfra.plotrefline(             ...
                           q,-dqdt,                      ...
                           'refline','upperenvelope',    ...
                           'labels',reflabels            ...
                           );

         % make ylimits span the min dq/dt to the upper envelope at max Q
         yupplim = ab(n,1)*max(xlims)^ab(n,2);

      case 'lowerenvelope'
         [h(n),ab(n,:)] =  bfra.plotrefline(             ...
                           q,-dqdt,                      ...
                           'refline','lowerenvelope',    ...
                           'labels',reflabels            ...
                           );

         ylowlim = min(0.8.*ab(n,1),0.8*min(ylims));

      case 'bestfit'
         [h(n),ab(n,:)] = bfra.plotrefline(              ...
                           q,-dqdt,                      ...
                           'refline','bestfit',          ...
                           'labels',false                ...
                           );

         h(n).LineWidth = 2;

      case 'userfit'

         [h(n),ab(n,:)] =  bfra.plotrefline(             ...
                           q,-dqdt,                      ...
                           'refline','userfit',          ...
                           'userab',userab,              ...
                           'labels',reflabels,           ...
                           'mask',mask                   ...
                           );
   end

   out.ab.(reflines{n}) = ab(n,:);

end

set(gca,'YLim',[ylowlim yupplim]);

% plot rain if provided
if all(~isnan(rain))
   hrain = plotrain(ax,h0,rain,q,-dqdt);
else
   hrain = nan;
end

% leaving this out for now   
if addlegend == true

   % check if both userfit and bestfit are requested
   fitcheck = {'bestfit','userfit'};

   if all(ismember(fitcheck,reflines))

      % ------------------------------------
%          % put them both in the legend
%          ibf   = ismember(reflines,fitcheck);
%          hleg  = h(ibf);
%          
%          ibest = strcmp(reflines,'bestfit');
%          iuser = strcmp(reflines,'userfit');
%          tbest = [bfra.aQbString(ab(ibest,:),'printvalues',true) ' (NLS fit)'];
%          tuser = [bfra.aQbString(ab(iuser,:),'printvalues',true) ' (user fit)'];
%          
%          % if user text provided, swap it out
%          if ~isempty(usertext)
%             tuser = [bfra.aQbString(ab(iuser,:),'printvalues',true) ' (' usertext ')'];
%          end
%          ltext = {tbest; tuser};
      % ------------------------------------

      % only put bestfit in the legend
      ibf   = strcmp(reflines,'bestfit');
      hleg  = h(ibf);
      ltext = bfra.aQbString(ab(ibf,:),'printvalues',true);
      ltext = [ltext ' (' upper(usertext) ' fit)']; 
      %ltext = [ltext ' (nonlinear least-squares)'];

   % check if either userfit or bestfit are requested
   elseif any(ismember(fitcheck,reflines))

      % use whichever one was requested
      ibf   = ismember(reflines,fitcheck);
      hleg  = h(ibf);
      ltext = bfra.aQbString(ab(ibf,:),'printvalues',true);

      if ~isempty(usertext)
         ltext = [ltext ' (' upper(usertext) ' fit)'];
      elseif ~any(ismember(reflines,'userfit'))
         ltext = [ltext ' (NLS fit)'];
      elseif ~any(ismember(reflines,'bestfit'))
         ltext = [ltext ' (MLE fit)'];
      end

   end

   if isobject(hrain)
      hleg  = [hleg hrain];
      ltext = {ltext,'rain'};
   end

   l = legend(hleg,ltext,'location','nw','interpreter','latex','AutoUpdate','off');
else
   l = nan;
end

% package the output
out.fig        = fig;
out.scatter    = h0;
out.mask       = h1;
out.reflines   = h;
out.ax         = gca;
out.hrain      = hrain;
%    out.hcloud    = h0;
%    out.hb1       = h1;
%    out.hb3       = h2;
%    out.hupper    = h3;
out.legend     = l;

% 
%    out.ab         = ab;

% snapnow;


function hrain = plotrain(ax,h,rain,x,y)
   
   % ax is the axis to plot into
   % h is the handle of the plotted q/dqdt to get the marker size to scale
   % the rain circles
   % x and y are q -dqdt
   
% add rain. scale the circles such that 1 mm of rain equals the size of
% the plotted circles 
if sum(rain)==0
   hrain = nan;
else

% scatter is producing pixelated symbols so I use plot instead
  %sz    = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
  %scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)

  % this mimics the way scatter scales the circles
   sz    = h.MarkerSize + sqrt(pi.*(rain(rain>0)).^2);
   x     = x(rain>0);
   y     = y(rain>0);

   hold on;
   for n = 1:numel(sz)
      hrain(n) = plot(ax,x(n),y(n),'o','MarkerSize',sz(n), ...
                  'MarkerFaceColor','none','Color','m','LineWidth',1);
   end
end
