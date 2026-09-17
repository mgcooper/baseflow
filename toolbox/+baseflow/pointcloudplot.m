function varargout = pointcloudplot(q,dqdt,varargin)
   %POINTCLOUDPLOT Plot a point-cloud diagram to estimate aquifer parameters.
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
   %     reflines    =  cell array of chars indicating what type of reflines to
   %                    plot
   %     reflabels   =  logical indicating whether to add labels
   %     blate       =  late-time b parameter in -dqdt = aq^b (dimensionless)
   %     userab      =  2x1 double indicating a user-defined intercept,slope
   %                    pair
   %     precision   =  scalar double indicating the precision in the x data,
   %                    used to compute the 'lower envelope'
   %     timestep    =  scalar double indicating the timestep of the x data,
   %                    used to compute the 'lower envelope'
   %     addlegend   =  logical indicating whether to add a legend or not
   %     usertext    =  char that gets added to the legend if refline 'userfit'
   %                    (to indicate what is being plotted, maybe a custom user
   %                    model)
   %     rain        =  vector double of rainfall (mm/time)
   %     labelstyle  =  char, 'arrow' (default) or 'line'. 'arrow' points an
   %                    arrow at each labeled reference line and writes the
   %                    label beside it. 'line' writes the label along the
   %                    line, as the upper-envelope label is written.
   %     labelcolor  =  rgb triplet for the label text and the label arrow.
   %                    Defaults to the line color.
   %     labelfontsize = scalar double, the reference-line label font size.
   %                    Default 10, the factory axes font size.
   %     fontsize    =  scalar double, the axes font size, which sets the
   %                    tick labels and the axis labels. Default 12.
   %     legendfontsize = scalar double, the legend font size. Default 12.
   %     axislimits  =  char, one of 'snap' (default), 'decades', or 'none'.
   %                    'snap' moves an axis limit out to its decade when
   %                    that decade is within a quarter decade, so the axis
   %                    corner carries a tick. 'decades' moves every limit
   %                    out to its decade. 'none' keeps the limits the data
   %                    sets.
   %     ax          =  graphic axis to plot into
   %
   % Example
   %
   %  Generate test data. Plot the point cloud with early- and late-time
   %  reference lines:
   %
   %     [t, q, dqdt] = baseflow.generateTestData(1e-2, 1.5, 100);
   %     h = baseflow.pointcloudplot(q, dqdt, ...
   %        'reflines', {'early', 'late'}, 'reflabels', true);
   %
   % See also: fitab, plotdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % Note: ab is for 'reflines','userfit' so a pre-computed ab can be plotted

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [q, dqdt, mask, reflines, reflabels, blate, userab, precision, ...
      timestep, addlegend, usertext, rain, axislimits, labelstyle, ...
      labelcolor, labelfontsize, fontsize, legendfontsize, ax] = ...
      parseinputs(q, dqdt, varargin{:});

   % create the figure / axes
   suppliedaxes = isaxis(ax) && not(isempty(ax));
   if not(suppliedaxes)
      figure;
      ax = gca;
   end
   fig = get(ax, 'Parent');

   % Size the figure only when this function created it. A caller that
   % supplies an axes owns the figure and the layout of its panels.
   % sizefigure keeps the position the figure was given, and plotdqdt
   % takes its size from the same place.
   if not(suppliedaxes)
      sizefigure(fig);
   end

   % plot the data
   h0 = loglog(ax, q, -dqdt, 'o');
   formatPlotMarkers('markersize', 6, 'suppliedline', h0);
   hold(ax, 'on'); grid(ax, 'off');

   % add circles around the t>tau0 values if requested
   if sum(mask) < numel(q)
      h1 = scatter(ax, q(mask), -dqdt(mask), 'r');
   else
      h1 = [];
   end

   % add some space around the data
   xlims = xlim(ax);
   ylims = ylim(ax);
   ylowlim = min(ylims);
   yupplim = max(ylims);

   % Widen x here, before the reference lines are drawn across this range.
   % plotrefline restores the limits it finds, so a later widening would
   % leave every line short of the axis edge. xlims keeps the data range,
   % which the upper-envelope y limit below needs.
   xlim(ax, snaploglims(xlims, [0.9 1.1], axislimits));
   % xlim([xlims(1)/(log10(xlims(2))-log10(xlims(1))) *.09 xlims(2)*1.1]);

   % Set the axes font size, which sets the tick labels, and set the axis
   % labels to the same size. A startup file can raise the axes font size,
   % and the tick labels then crowd the axes.
   set(ax, 'FontSize', fontsize);

   % set xylabels and init containers for reflines
   if isoctave
      xlabel(ax, 'Q (m^3 d^{-1})','FontSize',fontsize, 'Interpreter', 'tex');
      ylabel(ax, '-dQ/dt (m^3 d^{-2})','FontSize', fontsize, ...
         'Interpreter', 'tex');

      h = zeros(numel(reflines),1);
   else
      xlabel(ax, baseflow.getstring('Q','units',true), ...
         'FontSize', fontsize, 'Interpreter', 'latex');
      ylabel(ax, baseflow.getstring('dQdt','units',true), ...
         'FontSize', fontsize, 'Interpreter', 'latex');

      h = gobjects(numel(reflines),1);
   end

   % initialize array to hold parameters a and b
   ab = nan(numel(reflines),2);

   % add reference lines
   for n = 1:numel(reflines)
      
      switch reflines{n}
         case 'early'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','earlytime',        ...
                              'refslope',3,                 ...
                              'labels',reflabels,           ...
                              'labelstyle',labelstyle,      ...
                              'labelcolor',labelcolor,      ...
                              'labelfontsize',labelfontsize,...
                              'mask',mask,                  ...
                              'ax',ax                       ...
                              );
            set(h(n),'LineWidth',1);
            
         case 'late'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','latetime',         ...
                              'refslope',blate,             ...
                              'labels',reflabels,           ...
                              'labelstyle',labelstyle,      ...
                              'labelcolor',labelcolor,      ...
                              'labelfontsize',labelfontsize,...
                              'mask',mask,                  ...
                              'ax',ax                       ...
                              );
            set(h(n),'LineWidth',1);
            
         case 'upperenvelope'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','upperenvelope',    ...
                              'labels',reflabels,           ...
                              'labelstyle',labelstyle,      ...
                              'labelcolor',labelcolor,      ...
                              'labelfontsize',labelfontsize,...
                              'timestep',timestep,          ...
                              'ax',ax                       ...
                              );
            % make ylimits span the min dq/dt to the upper envelope at max Q
            yupplim = ab(n,1)*max(xlims)^ab(n,2);
            
         case 'lowerenvelope'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','lowerenvelope',    ...
                              'labels',reflabels,           ...
                              'labelstyle',labelstyle,      ...
                              'labelcolor',labelcolor,      ...
                              'labelfontsize',labelfontsize,...
                              'precision',precision,        ...
                              'timestep',timestep,          ...
                              'ax',ax                       ...
                              );
            ylowlim = min(0.8.*ab(n,1),0.8*min(ylims));
            
         case 'bestfit'
            [h(n),ab(n,:)] = baseflow.plotrefline(              ...
                              q,-dqdt,                      ...
                              'refline','bestfit',          ...
                              'labels',false,               ...
                              'ax',ax                       ...
                              );
            set(h(n),'LineWidth',2);
            
         case 'userfit'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','userfit',          ...
                              'userab',userab,              ...
                              'labels',reflabels,           ...
                              'labelstyle',labelstyle,      ...
                              'labelcolor',labelcolor,      ...
                              'labelfontsize',labelfontsize,...
                              'mask',mask,                  ...
                              'ax',ax                       ...
                              );
      end
      out.ab.(reflines{n}) = ab(n,:);
   end

   % ylowlim already carries the 0.8 factor set in the loop, so pass no
   % padding. The limits keep the values above unless a decade is near.
   set(ax,'YLim', snaploglims([ylowlim yupplim], [1 1], axislimits));

   % plotrefline set the ticks from the limits that were current when each
   % line was drawn, so every decade the limits above add needs a new tick.
   % Name each axis, because setlogticks skips an axis in manual tick mode.
   setlogticks(ax, 'axset', 'x');
   setlogticks(ax, 'axset', 'y');

   % A label written along a line was rotated with the limits that were
   % current when it was drawn. Reset each angle to the final limits,
   % because Octave installs no listener to do it.
   relayoutloglogtext(ax);

   % plot rain if provided
   if all(~isnan(rain))
      hrain = plotrain(ax, h0, rain, q, -dqdt);
   else
      hrain = nan;
   end

   % leaving this out for now
   if addlegend == true

      % check if both userfit and bestfit are requested
      fitcheck = {'bestfit', 'userfit'};

      if all(ismember(fitcheck,reflines))

         % ------------------------------------
         % % put them both in the legend
         % ibf   = ismember(reflines,fitcheck);
         % hleg  = h(ibf);
         %
         % ibest = strcmp(reflines,'bestfit');
         % iuser = strcmp(reflines,'userfit');
         % tbest = [baseflow.aQbString(ab(ibest,:),'printvalues',true) ' (NLS fit)'];
         % tuser = [baseflow.aQbString(ab(iuser,:),'printvalues',true) ' (user fit)'];
         %
         % % if user text provided, swap it out
         % if ~isempty(usertext)
         %    tuser = [baseflow.aQbString(ab(iuser,:),'printvalues',true) ' (' usertext ')'];
         % end
         % ltext = {tbest; tuser};
         % ------------------------------------

         % only put bestfit in the legend
         keep = strcmp(reflines, 'bestfit');
         hleg = h(keep);
         ltxt = baseflow.aQbString(ab(keep, :), 'printvalues', true);
         ltxt = [ltxt ' (' upper(usertext) ' fit)'];
         %ltxt = [ltxt ' (nonlinear least-squares)'];

         % check if either userfit or bestfit are requested
      elseif any(ismember(fitcheck, reflines))

         % use whichever one was requested
         keep = ismember(reflines, fitcheck);
         hleg = h(keep);
         ltxt = baseflow.aQbString(ab(keep, :), 'printvalues', true);

         if ~isempty(usertext)
            ltxt = [ltxt ' (' upper(usertext) ' fit)'];
         elseif ~any(ismember(reflines,'userfit'))
            ltxt = [ltxt ' (NLS fit)'];
         elseif ~any(ismember(reflines,'bestfit'))
            ltxt = [ltxt ' (MLE fit)'];
         end

      else
         % this could mean only late-time or early-time or other requested
         hleg = h;
         ltxt = reflines;
      end

      % plotrain returns the handles of the rain circles, or nan when no
      % rain is plotted. Octave returns numeric handles, so use the shared
      % islinehandle predicate rather than isobject.
      if islinehandle(hrain)
         % plotrain draws one circle per wet point, so one handle carries
         % the legend entry. hleg is a row for a fit line and a column for
         % the reference lines, and a caller can pass reflines as a row or
         % a column, so concatenate both lists down a column. ltxt is a
         % char for a fit line and a cell for the reference lines, so
         % cellstr gives one list for both.
         hleg = [hleg(:); hrain(1)];
         ltxt = cellstr(ltxt);
         ltxt = [ltxt(:); {'rain'}];
      end

      % aQbString returns the equation in latex. Octave has no latex text
      % interpreter, so drop the math delimiters and read it as tex there.
      if isoctave
         ltxt = strrep(ltxt, '$', '');
         interpreter = 'tex';
      else
         interpreter = 'latex';
      end

      L = legend(hleg, ltxt, 'location', 'northwest', ...
         'interpreter', interpreter, 'FontSize', legendfontsize, ...
         'AutoUpdate', 'off');

   else
      L = nan;
   end
   % package the output
   if nargout == 1
      out.fig        = fig;
      out.scatter    = h0;
      out.mask       = h1;
      out.reflines   = h;
      out.ax         = ax;
      out.hrain      = hrain;
      out.legend     = L;
      
      varargout{1} = out;
   end
end

%% LOCAL FUNCTIONS
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
      % sz = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
      % scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)

      % this mimics the way scatter scales the circles
      sz = get(h,'MarkerSize') + sqrt(pi.*(rain(rain>0)).^2);
      x = x(rain>0);
      y = y(rain>0);

      hold(ax, 'on');
      for n = numel(sz):-1:1
         hrain(n) = plot(ax,x(n),y(n),'o','MarkerSize',sz(n), ...
            'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
end

%% INPUT PARSER
function [q, dqdt, mask, reflines, reflabels, blate, userab, precision, ...
      timestep, addlegend, usertext, rain, axislimits, labelstyle, ...
      labelcolor, labelfontsize, fontsize, legendfontsize, ax] = ...
      parseinputs(q, dqdt, varargin)

   % The axis-limit policies snaploglims accepts, with the default first.
   axislimitvalues = {'snap', 'decades', 'none'};

   % The label styles labelrefline draws, with the default first.
   labelstyles = {'arrow', 'line'};

   % The MATLAB factory axes font size, which the reference-line labels
   % take, and the axes font size this function sets.
   defaultlabelfontsize = 10;
   defaultfontsize = 12;

   parser = inputParser;
   parser.addRequired('q', @isnumeric);
   parser.addRequired('dqdt', @isnumeric);
   parser.addParameter('mask', true(size(q)), @islogical);
   parser.addParameter('reflines', {'bestfit'}, @iscell);
   parser.addParameter('reflabels', false, @islogical);
   parser.addParameter('blate', 1, @isnumeric);
   parser.addParameter('userab', [1 1], @isnumeric);
   parser.addParameter('precision', 1, @isnumeric);
   parser.addParameter('timestep', 1, @isnumeric);
   parser.addParameter('addlegend', true, @islogical);
   parser.addParameter('usertext', '', @ischar);
   parser.addParameter('rain', nan, @isnumeric);
   parser.addParameter('axislimits', axislimitvalues{1}, ...
      @(policy) any(validatestring(policy, axislimitvalues)));
   parser.addParameter('labelstyle', labelstyles{1}, ...
      @(style) any(validatestring(style, labelstyles)));
   parser.addParameter('labelcolor', [], @islabelcolor);
   parser.addParameter('labelfontsize', defaultlabelfontsize, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('fontsize', defaultfontsize, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('legendfontsize', defaultfontsize, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('ax', emptyaxes(), @isaxis);
   parser.FunctionName = 'baseflow.pointcloudplot';
   
   parser.parse(q, dqdt, varargin{:});

   mask = parser.Results.mask;
   reflines = parser.Results.reflines;
   reflabels = parser.Results.reflabels;
   blate = parser.Results.blate;
   userab = parser.Results.userab;
   precision = parser.Results.precision;
   timestep = parser.Results.timestep;
   addlegend = parser.Results.addlegend;
   usertext = parser.Results.usertext;
   rain = parser.Results.rain;
   ax = parser.Results.ax;

   labelcolor = parser.Results.labelcolor;
   labelfontsize = parser.Results.labelfontsize;
   fontsize = parser.Results.fontsize;
   legendfontsize = parser.Results.legendfontsize;

   % validatestring returns the member of the list, so a partial value such
   % as 'dec' reaches snaploglims as 'decades'.
   axislimits = validatestring(parser.Results.axislimits, axislimitvalues);
   labelstyle = validatestring(parser.Results.labelstyle, labelstyles);
end
