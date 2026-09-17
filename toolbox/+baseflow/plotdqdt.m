function [hFits,Picks,Fits] = plotdqdt(q,dqdt,varargin)
   %PLOTDQDT Plot the log-log q vs dq/dt point-cloud
   %
   % Syntax
   %
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(q,dqdt)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'fitmethod',fitmethod)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'pickmethod',pickmethod)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'weights',weights)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'ax',axis_object)
   %
   % Required inputs
   %
   %     q     =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
   %     dqdt  =  discharge rate of change (L T^-2)
   %
   % Optional name-value inputs
   %
   %     labelplot = logical, default false. When true, draw the b-value
   %                 refline arrows and labels (see labelReflines).
   %     reflines  = cell array of chars naming the reference lines to draw.
   %                 The members are 'upperenvelope', 'lowerenvelope',
   %                 'late', and 'early'. The default draws all four. Pass a
   %                 shorter list to leave a line out, for example
   %                 {'upperenvelope', 'late', 'early'} to drop the
   %                 measurement-precision line at the foot of the cloud.
   %     axislimits = char, one of 'snap' (default), 'decades', or 'none'.
   %                 'snap' moves an axis limit out to its decade when that
   %                 decade is within a quarter decade, so the axis corner
   %                 carries a tick. 'decades' moves every limit out to its
   %                 decade. 'none' keeps the limits the data sets.
   %     labelcolor = rgb triplet for the label text and the label arrow.
   %                 Default black, so a figure theme does not recolor them.
   %     labelfontsize = scalar double, the label font size. Default 10, the
   %                 factory axes font size, so a startup file that raises
   %                 the axes font size does not enlarge the labels.
   %     labelstyle = char, 'arrow' (default) or 'line'. 'arrow' points an
   %                 arrow at each labeled reference line and writes the
   %                 label beside it. 'line' writes the label along the
   %                 line, as the upper-envelope label is written.
   %     fontsize  = scalar double, the axes font size, which sets the tick
   %                 labels and the axis labels. Default 12, the size
   %                 pointcloudplot uses.
   %     legendfontsize = scalar double, the legend font size. Default 12.
   %
   % Example
   %
   %  Plot the point cloud for the longest detected recession event. Fit
   %  -dQ/dt = aQ^b with ordinary least squares:
   %
   %     [T, Q, R] = baseflow.loadExampleData();
   %     Events = baseflow.getevents(T, Q, R);
   %     i = Events.eventTags == mode(Events.eventTags);
   %     [q, dqdt] = baseflow.getdqdt(Events.eventTime(i), ...
   %        Events.eventFlow(i), Events.eventRain(i), 'ETS');
   %     hFits = baseflow.plotdqdt(q, dqdt, 'fitmethod', 'ols');
   %
   % See also: getdqdt, fitdqdt

   % NOTE: now that pickFitter calls baseflow.fitab, this function does
   % everything that a complete workflow would do, i think, and therefore
   % should be renamed eventually (except it doesn't pick events)

   % NOTE: rain is optional b/c at this point, events are picked

   % NOTE: this is only called from getdqdt, and only if 'pickmethod' is
   % something other than 'none'.

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [q, dqdt, fitmethod, pickmethod, plotfits, showfig, weights, rain, ax, ...
      blate, precision, timestep, ~, labelplot, reflines, axislimits, ...
      labelcolor, labelfontsize, labelstyle, fontsize, legendfontsize] = ...
      parseinputs(q, dqdt, mfilename, varargin{:});

   % INIT OUTPUT
   [hFits, Fits, Picks] = initOutput();

   % Prep fits
   [~, ~, logx, logy, weights, ok] = baseflow.prepfits(q, dqdt, ...
      'weights', weights);

   if not(ok)
      return
   end

   % Pick fits
   Picks = fitSelector(logx, logy, weights, pickmethod, rain);

   % Fit picks
   Fits = pickFitter(Picks, fitmethod);

   % plot the fits
   hFits = plotFits(Fits, Picks, fitmethod, ax, plotfits,         ...
      showfig, blate, timestep, precision, labelplot, reflines,    ...
      axislimits, labelcolor, labelfontsize, labelstyle, fontsize, ...
      legendfontsize);
end

%% SELECT FITS
function Picks = fitSelector(q,dqdt,weights,pickmethod,rain)

   switch pickmethod
      case 'none'  % do nothing (use the entire event)
         istart = [];
         istop = [];

      case 'auto' % auto detect transition between early/late time

         if isoctave
            error('auto detection not enabled on Octave')
         end

         % if called w/o output, it will generate a figure
         chgpts = findchangepts(dqdt, 'MaxNumChanges', 2, 'Statistic', ...
            'linear', 'MinDistance', 2);
         nPicks = numel(chgpts);

         % get the segment start/ends
         istart   = [ 1;                chgpts(1:nPicks) ];
         istop    = [ chgpts(1:nPicks); numel(q);        ];

         % exclude segments <4. these are always included in the event fit
         rlengths = istop - istart + 1;
         ok       = rlengths > 4;
         istart   = istart(ok);
         istop    = istop(ok);

      case 'manual'

         % pause helps with buggy ginput
         pickFig     = eventPlotter(q, dqdt); pause(0.5);
         pickedPts   = baseflow.deps.ginputc(); pause(0.5);
         startPts    = pickedPts(1:2:end);
         endPts      = pickedPts(2:2:end);

         close(pickFig);

         if isodd(numel(pickedPts))
            error('baseflow:plotdqdt:oddNumberPickedPoints', ...
               'Each manually-selected recession segment must have one start and one end point.')
         end

         % for manual, need to find the indices
         istart = nan(size(startPts));
         istop  = nan(size(startPts));

         for n = 1:numel(startPts)
            difStart = abs(q - startPts(n));
            difStop = abs(q - endPts(n));
            istart(n) = findmin(difStart, 1, 'first');
            istop(n) = findmin(difStop, 1, 'first');
         end
   end

   % add the full-event to the start/stop indices
   istart = [istart; 1];
   istop  = [istop; numel(q)];
   nPicks = numel(istart);

   if pickmethod ~= "none"
      fprintf('%.f picks identified +event = %.f\n', nPicks-1, nPicks)
   end

   % cycle through the picks and pull out the data
   Picks.Q           = cell(  nPicks,1 );
   Picks.dQdt        = cell(  nPicks,1 );
   Picks.Weights     = cell(  nPicks,1 );
   Picks.Rain        = cell(  nPicks,1 );

   % find the indices of the picked points on the q,dqdt data arrays
   for n = 1:nPicks
      Picks.Q{n}        = q(        istart(n):istop(n)   );
      Picks.dQdt{n}     = dqdt(     istart(n):istop(n)   );
      Picks.Weights{n}  = weights(  istart(n):istop(n)   );
      Picks.Rain{n}     = rain(     istart(n):istop(n)   );
   end

   Picks.nPicks        = nPicks;
   Picks.istart        = istart;
   Picks.istop         = istop;
   Picks.runlengths    = istop-istart+1;
end

%% FIT PICKS
function Fits = pickFitter(Picks,fitmethod)

   for n = 1:Picks.nPicks

      logq = Picks.Q{n};
      logdqdt = Picks.dQdt{n};
      weights = Picks.Weights{n};

      q = exp(logq);
      dqdt = -exp(logdqdt);

      switch fitmethod

         case {'ols','qtl','nls','mle'}
            Fit = baseflow.fitab(q, dqdt, fitmethod);
         case 'comp'
            FitO = baseflow.fitab(q,dqdt,'ols','weights',weights);
            FitQ = baseflow.fitab(q,dqdt,'qtl','weights',weights);
            FitN = baseflow.fitab(q,dqdt,'nls','weights',weights);

            Fits.abqtl(n,:) = FitO.ab;
            Fits.abnls(n,:) = FitN.ab;
            Fits.abqtl(n,:) = FitQ.ab;
      end

      Fits.ab(n,:) = Fit.ab;
      Fits.xplot(n,:) = linspace(0.75*min(q), max(q)*1.25,50);
      Fits.yplot(n,:) = Fits.ab(n,1)*Fits.xplot(n,:).^Fits.ab(n,2);
   end
   Fits.nFits = Picks.nPicks;
end

%% PLOT FITS
function h = plotFits(Fits,Picks,fitmethod,ax,plotfits, ...
      showfig,blate,timestep,precision,labelplot,reflines,axislimits, ...
      labelcolor,labelfontsize,labelstyle,fontsize,legendfontsize)

   if plotfits == true
      if showfig == true
         if strcmp(ax, 'none')
            sizefigure(figure());
            ax = gca;
         end
      else
         sizefigure(figure('visible','off'));
         ax = gca;
      end
      h.ax = ax;
   else
      h = []; return;
   end
   c  =  [
      0        0.447    0.741;
      0.85     0.325    0.098;
      0.929    0.694    0.125;
      0.494    0.184    0.556;
      0.466    0.674    0.188;
      0.301    0.745    0.933;
      0.635    0.078    0.184  ];


   nFits = Fits.nFits;
   nPlot = max(nFits,1); % max(nFits-1,1);
   ltext = repmat({''},nPlot,1);

   % this converts the entire event back to linear space
   x = exp(Picks.Q{end});
   y = exp(Picks.dQdt{end});
   rain = Picks.Rain{end};
   hold(ax, 'on');

   % Plot the entire event and get ax lims before setting log scale. Note: in
   % an earlier version this was moved after the 1:nPlot loop for the case
   % where multiple events are plotted, the difference is how the lines plot on
   % top of the scatter points.
   h.scatter = plot(h.ax, x, y, 'o', 'MarkerSize', 8, ...
      'MarkerFaceColor', c(1,:), 'MarkerEdgeColor', 'none');

   for n = 1:nPlot

      % 'comp' not implemented, this is a template
      if strcmp(fitmethod,'comp')
         abnls = Fits.abnls(n,:);
         xplot = Fits.xplot(n,:);
         yplot = abnls(1).*xplot.^abnls(2);

         h.plots{n} = plot(h.ax,xplot,yplot,':','Color',c(n+1,:));
         ltext{n} = baseflow.aQbString(abnls,'printvalues',true);

      else
         % if Fits.ab(n,2)<0; continue; end
         xplot = Fits.xplot(n,:);
         yplot = Fits.yplot(n,:);
         if nPlot == 1
            % if only one plot, use black dots
            h.plots{n} = plot(h.ax,xplot,yplot,':','Color','k');
         else
            % otherwise cycle through the colors
            h.plots{n} = plot(h.ax,xplot,yplot,':','Color',c(n+1,:));
         end
         ltext{n} = baseflow.aQbString(Fits.ab(n,:),'printvalues',true);
      end
   end

   % Remove empty legend text
   ltext = ltext(~ismember(ltext,''));
   xtext = baseflow.getstring('Q','units',true);
   ytext = baseflow.getstring('dQdt','units',true);

   % Format the figure
   axis(h.ax, 'tight'); axis(h.ax, 'square');
   set(h.ax, 'XScale', 'log', 'YScale', 'log');

   if isoctave
      ltext = latex2tex(ltext);
      xtext = latex2tex(xtext);
      ytext = latex2tex(ytext);
      interpreter = 'tex';
   else
      interpreter = 'latex';
   end

   % Set the axes font size, which sets the tick labels, and set the axis
   % labels to the same size. A startup file can raise the axes font size,
   % and the tick labels then crowd the axes.
   set(h.ax, 'FontSize', fontsize);
   xlabel(h.ax, xtext, 'Interpreter', interpreter, 'FontSize', fontsize);
   ylabel(h.ax, ytext, 'Interpreter', interpreter, 'FontSize', fontsize);

   xlimkeep = get(h.ax, 'XLim');
   ylimkeep = get(h.ax, 'YLim');

   % Keep the data range. The upper-envelope y limit below evaluates the
   % envelope at the largest x of the data, not at a widened axis limit.
   xdatalim = xlimkeep;

   % Widen x here, before the reference lines are drawn across this range.
   % plotrefline restores the limits it finds, so a later widening would
   % leave every line short of the axis edge.
   xlimkeep = snaploglims(xlimkeep, [1 1], axislimits);
   set(h.ax, 'XLim', xlimkeep);

   % Add reference lines. abUpper and abLower stay empty when the caller
   % leaves that line out, and the y limits below then use the data range.
   abUpper = [];
   abLower = [];
   for n = 1:numel(reflines)

      switch reflines{n}
         case 'upperenvelope'
            [~,abUpper] = baseflow.plotrefline(x,y, ...
               'refline',  'upperenvelope',  ...
               'timestep', timestep, ...
               'ax', h.ax );

         case 'lowerenvelope'
            % Pass timestep. plotrefline computes the intercept as
            % precision*3600*24/timestep, so its own default of one day
            % draws the line at the wrong height for another timestep.
            [~,abLower]  = baseflow.plotrefline(x,y, ...
               'refline',  'lowerenvelope',  ...
               'precision',precision, ...
               'timestep', timestep, ...
               'ax', h.ax );

         case 'late'
            [~,abLate] = baseflow.plotrefline(x,y, ...
               'refline', 'latetime', ...
               'refslope', blate, ...
               'ax', h.ax );

            % add the ref-point a/b values
            h.aLate  = abLate(1);
            h.bLate  = abLate(2);

         case 'early'
            [~,abEarly] = baseflow.plotrefline(x,y, ...
               'refline', 'earlytime', ...
               'ax', h.ax );

            % add the ref-point a/b values
            h.aEarly = abEarly(1);
            h.bEarly = abEarly(2);
      end
   end

   % make the ylimits span the minimum dq/dt to the upper envelope at max Q
   if timestep >= 1
      ylowlim = min(ylimkeep);
      yupplim = max(ylimkeep);
      if not(isempty(abLower))
         ylowlim = min(0.8 * abLower(1), ylowlim);
      end
      if not(isempty(abUpper))
         yupplim = abUpper(1) * max(xdatalim)^abUpper(2);
      end

      % ylowlim already carries the 0.8 factor, so pass no padding.
      set(h.ax, 'YLim', snaploglims([ylowlim yupplim], [1 1], axislimits));
   else

      % A subdaily timestep draws the envelopes where the daily intercept
      % does not describe the record, so the y limits stay at the data
      % range instead of reaching the upper envelope. Apply the limit
      % policy to that range.
      set(h.ax, 'YLim', snaploglims( ...
         [min(ylimkeep) max(ylimkeep)], [1 1], axislimits));
   end

   % plotrefline set the ticks from the limits that were current when each
   % line was drawn, so every decade the limits above add needs a new tick.
   % Name each axis, because setlogticks skips an axis in manual tick mode.
   setlogticks(h.ax, 'axset', 'x');
   setlogticks(h.ax, 'axset', 'y');

   % A label written along a line was rotated with the limits that were
   % current when it was drawn. Reset each angle to the final limits,
   % because Octave installs no listener to do it.
   relayoutloglogtext(h.ax);

   h = plotrain(h, rain, x, y);

   % I added this so rain is in the legend. plotrain returns the handles of
   % the rain circles, or nan when no rain is plotted, so the guard tests
   % islinehandle. isaxis is true only for an Axes, so it kept the rain
   % entry out of the legend and left the entry count short.
   if isfield(h, 'hrain') && islinehandle(h.hrain)
      ltext = [ltext(:); {'rain'}];
      hleg = [h.plots{:} h.hrain(1)];
   else
      hleg = [h.plots{:}];
   end

   h.leg = legend( hleg, ltext, ...
      'Location', 'northwest', 'Interpreter', interpreter, ...
      'FontSize', legendfontsize, 'AutoUpdate', 'off');
   grid(h.ax, 'off')

   % fprintf('%.f picks selected to plot\n',numel(ltext))
   if labelplot == true
      labelReflines(h, labelcolor, labelfontsize, labelstyle)
   end
end

%%
function labelReflines(h, labelcolor, labelfontsize, labelstyle)

   % Label a line only when plotFits drew it. The reflines option selects
   % the lines, so one or both of these pairs can be absent. labelrefline
   % draws the same arrow plotrefline draws for the point cloud.
   % Octave has no latex text interpreter.
   if isoctave
      interpreter = 'tex';
   else
      interpreter = 'latex';
   end

   % The late-time and early-time slopes are reference values, not fits,
   % so neither label carries b-hat. plotrefline labels the user fit of
   % the point cloud with b-hat through the same helper.
   isestimate = false;

   if isfield(h, 'aLate')
      labelrefline(h.ax, h.aLate, h.bLate, ...
         breflinetext(h.bLate, isestimate, interpreter), ...
         'Style', labelstyle, 'Color', labelcolor, ...
         'FontSize', labelfontsize, 'Interpreter', interpreter);
   end

   if isfield(h, 'aEarly')
      labelrefline(h.ax, h.aEarly, h.bEarly, ...
         breflinetext(h.bEarly, isestimate, interpreter), ...
         'Style', labelstyle, 'Color', labelcolor, ...
         'FontSize', labelfontsize, 'Interpreter', interpreter);
   end
end

%%
function h = plotrain(h,rain,x,y)

   % add rain. scale the circles such that 1 mm of rain equals the size of
   % the plotted circles
   if sum(rain)==0
      h.hrain = nan;
   else

      % scatter is producing pixelated symbols so I use plot instead
      %sz    = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
      %scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)

      % this mimics the way scatter scales the circles. Read the size with
      % get, because Octave returns a numeric handle, which takes no dot.
      s = get(h.scatter, 'MarkerSize') + sqrt(pi.*(rain(rain>0)).^2);
      x = x(rain>0);
      y = y(rain>0);

      hold(h.ax, 'on');

      % Count down so the handle array takes its size on the first pass.
      for n = numel(s):-1:1
         h.hrain(n) = plot(h.ax,x(n),y(n),'o','MarkerSize',s(n), ...
            'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
end

%%
function addRotatedText(xtxt,ytxt,txt,slope,axpos) %#ok<*DEFNU> 

   % https://stackoverflow.com/questions/52928360/rotating-text-onto-a-line-on-a-log-scale-in-matplotlib

   % to add text, need the slope in figure space
   xlims = xlim;
   ylims = ylim;
   xfact = axpos(1)/(log(xlims(2))-log(xlims(1)));
   yfact = axpos(2)/(log(ylims(2))-log(ylims(1)));   % slope adjustment
   atext = slope*atand(yfact/xfact);           % adjust angle

   text( xtxt,ytxt,txt,                   ...
      'HorizontalAlignment','center',     ...
      'VerticalAlignment', 'bottom',      ...
      'FontSize',12,                      ...
      'rotation',atext);
end

%% PLOT EVENT
function pickFig = eventPlotter(q,dqdt)
   pickFig = figure;
   scatter(q,dqdt,36,[0,0.447,0.741],'filled');
end

%% DETECT TRANSITION
function [istart, istop] = detectTransition(q,dqdt,istart,istop)

   nPicks   = numel(istart);
   rlengths = istop-istart+1;

   if nPicks == 3
      % if rlengths(1)>rlengths(2) && rlengths(3)>rlengths(2)

      q1    = q(istart(1):istop(1));
      q2    = q(istart(2):istop(2));
      q3    = q(istart(3):istop(3));
      dq1   = dqdt(istart(1):istop(1));
      dq2   = dqdt(istart(2):istop(2));
      dq3   = dqdt(istart(3):istop(3));

      % Jul 2024 - commented out b/c "wols" is not a function in the toolbox.
      % Not sure if this is supposed to be "ols" or a weighted version.
      % ab1   = baseflow.wols(log(q1), log(-dq1));
      % ab2   = baseflow.wols(log(q2), log(-dq2));
      % ab3   = baseflow.wols(log(q3), log(-dq3));

      % three cases we want to :
      % 1: a flat period between two recessions
      % 2: a flat period followed by another one then a recession
      % 2: a recession followed by two flat periods

      % Jul 2024 - commented out b/c "wols" is not a function in the toolbox.
      % if ab1(2)>1 && ab2(2)<1 && ab3(2)>1
      %    istart(2)   = [];
      %    istop(2)    = [];
      % end
      %end
   end
end

%% Initialize output
function [hFits, Fits, Picks] = initOutput()
   Fits.h = nan; Fits.abols= nan; Fits.abnls = nan; Fits.abqtl = nan;
   Picks.Q = nan; Picks.T = nan; Picks.dQdt = nan; Picks.R = nan;
   Picks.nPicks = nan; hFits = nan;
end

%% INPUT PARSER
function [q, dqdt, fitmethod, pickmethod, plotfits, showfig, weights, ...
      rain, ax, blate, precision, timestep, eventID, labelplot, reflines, ...
      axislimits, labelcolor, labelfontsize, labelstyle, fontsize, ...
      legendfontsize] = parseinputs(...
      q, dqdt, mfilename, varargin)

   % The reference lines plotFits draws. The names are the ones
   % pointcloudplot uses, so one value means the same line in both
   % functions, and the default draws the set this function always drew.
   defaultreflines = {'upperenvelope', 'lowerenvelope', 'late', 'early'};

   % The axis-limit policies snaploglims accepts, with the default first.
   axislimitvalues = {'snap', 'decades', 'none'};

   % The label styles labelrefline draws, with the default first.
   labelstyles = {'arrow', 'line'};

   % The MATLAB factory axes font size. A startup file can raise the axes
   % font size, so the labels take their size from this value instead.
   defaultfontsize = 10;

   % The axes font size this function sets, which pointcloudplot also uses.
   defaultaxesfontsize = 12;

   parser = inputParser;
   parser.FunctionName = ['baseflow.' mfilename];
   parser.CaseSensitive = false;
   parser.addRequired('q');
   parser.addRequired('dqdt');
   parser.addParameter('fitmethod', 'nls');
   parser.addParameter('pickmethod', 'none');
   parser.addParameter('plotfits', true);
   parser.addParameter('showfig', true, @islogical);
   parser.addParameter('weights', ones(size(q)));
   parser.addParameter('rain', zeros(size(q)));
   parser.addParameter('ax', 'none');
   parser.addParameter('blate', 1.0);
   parser.addParameter('precision', 1);
   parser.addParameter('timestep', 1);
   parser.addParameter('eventID', '', @ischar);
   parser.addParameter('labelplot', false, @islogical);
   parser.addParameter('reflines', defaultreflines, @iscell);
   parser.addParameter('axislimits', axislimitvalues{1}, ...
      @(policy) any(validatestring(policy, axislimitvalues)));
   parser.addParameter('labelcolor', [0 0 0], @islabelcolor);
   parser.addParameter('labelfontsize', defaultfontsize, @(x) isnumericscalar(x) && x > 0);
   parser.addParameter('labelstyle', labelstyles{1}, ...
      @(style) any(validatestring(style, labelstyles)));
   parser.addParameter('fontsize', defaultaxesfontsize, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('legendfontsize', defaultaxesfontsize, ...
      @(value) isnumericscalar(value) && value > 0);

   parser.parse(q, dqdt, varargin{:});

   q = parser.Results.q;
   ax = parser.Results.ax;
   dqdt = parser.Results.dqdt;
   rain = parser.Results.rain;
   blate = parser.Results.blate;
   showfig = parser.Results.showfig;
   weights = parser.Results.weights;
   eventID = parser.Results.eventID;
   timestep = parser.Results.timestep;
   plotfits = parser.Results.plotfits;
   labelplot = parser.Results.labelplot;
   precision = parser.Results.precision;
   fitmethod = parser.Results.fitmethod;
   pickmethod = parser.Results.pickmethod;
   reflines = parser.Results.reflines;
   labelcolor = parser.Results.labelcolor;

   % islabelcolor accepts empty, which asks for the default label color.
   if isempty(labelcolor)
      labelcolor = [0 0 0];
   end
   labelfontsize = parser.Results.labelfontsize;

   % validatestring returns the member of the list, so a partial value such
   % as 'dec' reaches snaploglims as 'decades'.
   axislimits = validatestring(parser.Results.axislimits, axislimitvalues);
   labelstyle = validatestring(parser.Results.labelstyle, labelstyles);
   fontsize = parser.Results.fontsize;
   legendfontsize = parser.Results.legendfontsize;

   if ~ischar(ax)
      validateattributes(ax, {'matlab.graphics.axis.Axes'},{'scalar'}, mfilename);
   end

   validateattributes(q, {'numeric'}, {'real','column'}, mfilename, 'q');
   validateattributes(dqdt, {'numeric'}, {'real','column'}, mfilename, 'dqdt');
   validateattributes(rain, {'numeric'}, {'real','column'}, mfilename);
   validateattributes(blate, {'numeric'}, {'real','scalar'}, mfilename);
   validateattributes(weights, {'numeric'}, {'real','column'}, mfilename);
   validateattributes(timestep, {'numeric', 'duration'}, {'nonempty'}, mfilename);
   validateattributes(plotfits, {'logical'}, {'scalar'}, mfilename);
   validateattributes(precision, {'numeric'}, {'nonempty'}, mfilename);
   % Require text, and check the value itself below. The Octave
   % validateattributes has no 'scalartext' attribute, and plotdqdt runs
   % on Octave through getdqdt with plotfits true.
   validateattributes(fitmethod, {'char', 'string'}, {'nonempty'}, mfilename);
   validateattributes(pickmethod, {'char', 'string'}, {'nonempty'}, mfilename);
end
