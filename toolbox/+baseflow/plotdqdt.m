function [hFits,Picks,Fits] = plotdqdt(q,dqdt,varargin)
   %PLOTDQDT Plot the log-log q vs dq/dt point-cloud
   %
   % Syntax
   %
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(q,dqdt)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'fitmethod',fitmethod)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'pickmethod',pickmethod)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'weights',weights)
   %     [hFits,Picks,Fits] = baseflow.plotdqdt(_,'useax',axis_object)
   %
   % Required inputs
   %
   %     q     =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
   %     dqdt  =  discharge rate of change (L T^-2)
   %
   % Optional name-value inputs
   %
   %
   % See also: getdqdt, fitdqdt

   % NOTE: now that pickFitter calls baseflow.fitab, this function does
   % everything that an complete workflow would do, i think, and therefore
   % should be renamed eventually (except it doesn't pick events)

   % NOTE: rain is optional b/c at this point, events are picked

   % NOTE: this is only called from getdqdt, and only if 'pickmethod' is
   % something other than 'none'.

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [q, dqdt, fitmethod, pickmethod, plotfits, showfig, weights, rain, ax, ...
      blate, precision, timestep, eventID, labelplot] = parseinputs( ...
      q, dqdt, mfilename, varargin{:});

   % INIT OUTPUT
   [hFits, Fits, Picks] = initOutput();

   % Prep fits
   [~, ~, logx, logy, weights, ok] = baseflow.prepfits(q, dqdt, ...
      'weights', weights);

   if ok == false
      return;
   end

   % Pick fits
   Picks = fitSelector(logx, logy, weights, pickmethod, rain);

   % Fit picks
   Fits = pickFitter(Picks, fitmethod);

   % plot the fits
   hFits = plotFits(Fits, Picks, fitmethod, ax, plotfits,         ...
      showfig, blate, timestep, precision, labelplot);
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
      Fits.xplot(n,:) = linspace(0.75*min(q),max(q)*1.25,50);
      Fits.yplot(n,:) = Fits.ab(n,1).*Fits.xplot(n,:).^Fits.ab(n,2);
   end
   Fits.nFits = Picks.nPicks;
end

%% PLOT FITS
function h = plotFits(Fits,Picks,fitmethod,ax,plotfits,    ...
      showfig,blate,timestep,precision,labelplot)

   if plotfits == true
      if showfig == true
         if strcmp(ax, 'none')
            figure('Position',[1 1 658 576]);
            ax = gca;
         end
      else
         figure('Position',[1 1 658  576],'visible','off');
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
   hold on;

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
   axis tight; axis square;
   set(h.ax, 'XScale', 'log', 'YScale', 'log');

   if isoctave
      ltext = latex2tex(ltext);
      xtext = latex2tex(xtext);
      ytext = latex2tex(ytext);
      interpreter = 'tex';
   else
      interpreter = 'latex';
   end

   xlabel(xtext, 'Interpreter', interpreter);
   ylabel(ytext, 'Interpreter', interpreter);

   xlimkeep = get(gca, 'XLim');
   ylimkeep = get(gca, 'YLim');

   % Add reference lines
   [hUpper,abUpper] = baseflow.plotrefline(x,y, ...
      'refline',  'upperenvelope',  ...
      'timestep', timestep );

   [hLower,abLower]  = baseflow.plotrefline(x,y, ...
      'refline',  'lowerenvelope',  ...
      'precision',precision );

   [hLate,abLate] = baseflow.plotrefline(x,y, ...
      'refline', 'latetime', ...
      'refslope', blate );

   [hEarly,abEarly] = baseflow.plotrefline(x,y, ...
      'refline', 'earlytime' );

   % add the ref-point a/b values
   h.aEarly = abEarly(1);
   h.bEarly = abEarly(2);
   h.aLate  = abLate(1);
   h.bLate  = abLate(2);

   % make the ylimits span the minimum dq/dt to the upper envelope at max Q
   if timestep >= 1
      ylowlim = min(0.8 * abLower(1), min(ylimkeep));
      yupplim = abUpper(1) * max(xlimkeep)^abUpper(2);

      set(gca, 'YLim', [ylowlim yupplim]);
   end

   h = plotrain(h, rain, x, y);

   % I added this so rain is in the legend
   if ~isoctave
      withwarnoff('MATLAB:legend:IgnoringExtraEntries');
   end
   
   if isfield(h, 'hrain') && isaxis(h.hrain)
      ltext = [ltext 'rain'];
      h.leg = legend( [h.plots{:} h.hrain(1)], ltext, ...
         'Location', 'northwest', 'Interpreter', interpreter, ...
         'FontSize', 13, 'AutoUpdate', 'off');
   else
      h.leg = legend( [h.plots{:} hUpper], ltext, ...
         'Location', 'northwest', 'Interpreter', interpreter, ...
         'FontSize', 13, 'AutoUpdate', 'off');
   end
   grid off

   % fprintf('%.f picks selected to plot\n',numel(ltext))
   if labelplot == true
      labelReflines(h)
   end

   % axpos = baseflow.deps.plotboxpos(gca);
   % only works with correct axes position
   % xtext = exp(mean(log(xlimkeep)));
   % addRotatedText(4*xtext,axb(aEarly,4*xtext,bEarly),'b=3',bEarly,axpos);
   % addRotatedText(2*xtext,axb(aLate,2*xtext,bLate),'b=1',1.5,axpos);
   % addRotatedText(1*xtext,axb(aMax,1*xtext,bMax),'upper envelope',1.5,axpos);
end

%%
function labelReflines(h)

   % Use the axis limits and the number of decades to place the labels
   ylims = ylim;
   xlims = xlim;

   ndecsy = log10(ylims(2)) - log10(ylims(1));
   ndecsx = log10(xlims(2)) - log10(xlims(1));

   % Place the late-time arrow above the first decade
   factor = 10;
   ya = 10 ^ ( log10(ylims(1)) + ndecsy/factor );
   xa = (ya / h.aLate) ^ (1 / h.bLate);

   % If xa is off the chart, adjust y and recompute
   while xa < xlims(1)
      factor = factor - 1;
      ya = 10 ^ ( log10(ylims(1)) + ndecsy/factor );
      xa = (ya / h.aLate) ^ (1 / h.bLate);
   end

   % Make the arrow span 1/10th or so of the total number of decades
   xa = [xa 10 ^ (log10(xa) + ndecsx/factor)];
   ya = [ya ya];

   % Convert from data units to normalized figure units
   [normX, normY] = normalizeDataCoordinates(gca, flip(xa), ya);

   % Place the arrow. When headwidth is adjusted the arrow tip is slightly
   % elongated, so adjust normX a tad bit
   normX(2) = normX(2)*1.02;
   annotation('arrow', normX, normY, 'HeadStyle', 'plain', 'HeadWidth', 4, ...
      'HeadLength', 8, 'LineWidth', 1)


   % Add the label
   if isoctave
      ta = sprintf('b=%.2f', h.bLate);
      text(1.05 * xa(2), ya(2), ta, ...
         'HorizontalAlignment', 'left', 'Interpreter', 'tex')
   else
      ta = sprintf('$b=%.2f$ ($\\hat{b}$)', h.bLate);
      text(1.05 * xa(2), ya(2), ta, ...
         'HorizontalAlignment', 'left', 'Interpreter', 'latex')
   end

   % Draw the early-time arrow
   xa = (ya(1) / h.aEarly) ^ (1 / h.bEarly);
   xa = [xa 10^(log10(xa) + ndecsx/factor)];

   % Convert from data units to normalized figure units
   [normX, normY] = normalizeDataCoordinates(gca, flip(xa), ya);
   normX(2) = normX(2)*1.01;

   % Place the arrow
   annotation('arrow', normX, normY, 'HeadStyle', 'plain', 'HeadWidth', 4, ...
      'HeadLength', 10, 'LineWidth', 1)

   % Add the label
   if isoctave
      ta = sprintf('b=%.0f', h.bEarly);
      text(1.05 * xa(2), ya(2), ta, ...
         'HorizontalAlignment', 'left', 'Interpreter', 'tex')
   else
      ta = sprintf('$b=%.0f$', h.bEarly);
      text(1.05 * xa(2), ya(2), ta, ...
         'HorizontalAlignment', 'left', 'Interpreter', 'latex')
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

      % this mimics the way scatter scales the circles
      s = h.scatter.MarkerSize + sqrt(pi.*(rain(rain>0)).^2);
      x = x(rain>0);
      y = y(rain>0);

      hold on;
      for n = 1:numel(s)
         h.hrain(n) = plot(x(n),y(n),'o','MarkerSize',s(n), ...
            'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
end

%%
function addRotatedText(xtxt,ytxt,txt,slope,axpos)

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
      ab1   = baseflow.wols(log(q1),log(-dq1));
      ab2   = baseflow.wols(log(q2),log(-dq2));
      ab3   = baseflow.wols(log(q3),log(-dq3));

      % three cases we want to :
      % 1: a flat period between two recessions
      % 2: a flat period followed by another one then a recession
      % 2: a recession followed by two flat periods

      if ab1(2)>1 && ab2(2)<1 && ab3(2)>1
         istart(2)   = [];
         istop(2)    = [];
      end
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
      rain, ax, blate, precision, timestep, eventID, labelplot] = parseinputs(...
      q, dqdt, mfilename, varargin)

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
   parser.addParameter('labelplot', true, @islogical);

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
   validateattributes(fitmethod, {'char', 'string'}, {'scalartext'}, mfilename);
   validateattributes(pickmethod, {'char', 'string'}, {'scalartext'}, mfilename);
end
