function varargout = plotrefline(x,y,varargin)
   %PLOTREFLINE Add a reference line to a point cloud plot.
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
   %     plotline =  logical indicating whether to add the line plot (for some
   %                 cases this function can be used to return the a/b values
   %                 only)
   %     linecolor = rgb triplet indicating the line color
   %     labelcolor = rgb triplet indicating the color of the label text and
   %                 the label arrow. Defaults to the value of linecolor, so
   %                 a label matches the line it annotates in any figure
   %                 theme. Pass [] for the same default.
   %     labelfontsize = scalar double indicating the label font size
   %     labelstyle = char indicating how to draw the labels of the
   %                 'latetime', 'earlytime', and 'userfit' lines. 'arrow',
   %                 the default, draws an arrow with the text beside it.
   %                 'line' draws the text along the line. The
   %                 'upperenvelope' label is along the line for both values.
   %     precision = scalar double indicating the precision in the x data, used
   %                 to compute the 'lower envelope'
   %     timestep  = scalar double indicating the timestep of the x data, used
   %                 to compute the 'lower envelope'
   %     ax       =  graphic axis to plot into
   %
   % See also: fitab, pointcloudintercept, pointcloudplot
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % NOTE: y comes in as -dq/dt, send it to baseflow.fitab as -y, and to refline
   % as y

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [x, y, mask, refline, refslope, userab, labels, refqtls, plotline, ...
      linecolor, labelcolor, labelfontsize, labelstyle, precision, ...
      timestep, ax] = parseinputs(x, y, varargin{:});

   % need options for how/if to apply the mask - e.g., we might want to show the
   % 'bestfit' to all data, and use the mask for late-time fit. also keep in
   % mind baseflow.eventphi calls this. mask is default true in parsing.

   % use this to find the equation of the line
   axb = @(a,x,b) a.*x.^b;

   % keep track of the original axis limits
   if plotline == true
      if isempty(ax)
         ax = gca;
      end
      hold(ax, 'on');
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
         F = baseflow.fitab(x(mask), -y(mask), 'ols', 'order', 1);
         a = F.ab(1);
         b = F.ab(2);
      case 'bestfit'
         F = baseflow.fitab(x(mask), -y(mask), 'nls');
         a = F.ab(1);
         b = F.ab(2);
      case 'userfit'
         a = userab(1);
         b = userab(2);
      case 'envelope'
         F = baseflow.fitab(x(mask), -y(mask), ...
            'envelope', 'refqtls', refqtls, 'order', refslope);
         a = F.ab(1);
         b = F.ab(2);
      case 'earlytime'
         if refslope == 1; refslope = 3; end
         F = baseflow.fitab(x, -y, ...
            'envelope', 'refqtls', [0.95 0.95], 'order', refslope);
         a = F.ab(1);
         b = F.ab(2);
      case 'latetime'
         F = baseflow.fitab(x(mask), -y(mask), ...
            'envelope', 'refqtls', [0.5 0.5], 'order', refslope);
         a = F.ab(1);
         b = F.ab(2);
      otherwise
         % use upper envelope
         b = 1;               % slope = 1
         a = 2/timestep;      % for daily, intercept = 2
   end

   % send back the ab
   href = []; % this gets sent back in case plotline false
   ab = [a;b];

   % Below here only needed if plot is requested
   if plotline == true

      xref = linspace(xlims(1),xlims(2),100);
      yref = axb(a,xref,b);

      switch refline
         case 'bestfit'
            href = loglog(ax,xref,yref,':','LineWidth',1,'Color',linecolor);
         case 'userfit'
            href = loglog(ax,xref,yref,'-','LineWidth',1,'Color',linecolor);
         otherwise
            href = loglog(ax,xref,yref,'-','LineWidth',0.5,'Color',linecolor);
      end

      % reset the x,ylims
      set(ax,'XLim',xlims,'YLim',ylims,'TickLabelInterpreter','tex')
      setlogticks(ax);

      if labels == true
         addlabels(ax,a,b,refline,labelcolor,labelfontsize,labelstyle)
      end
   end
   % if discharge were measured directly, then the lower envelope would be
   % the precision of the measurements, here I assume that it is 1 m3/s, and
   % this lower envelope would appear as a horizontal line, also at
   % integer multiples of it.
   
   switch nargout
      case 1
         varargout{1} = href;
      case 2
         varargout{1} = href;
         varargout{2} = ab;
   end
end

%% LOCAL FUNCTIONS
function addlabels(ax,a,b,refline,labelcolor,labelfontsize,labelstyle)

   switch refline

      %case {'latetime','earlytime','userfit','bestfit'}
      case {'latetime','earlytime','userfit'}

         % Octave has no latex text interpreter.
         if isoctave
            interpreter = 'tex';
         else
            interpreter = 'latex';
         end

         % The user fit is an estimate, so its label carries b-hat. The
         % early-time and late-time lines are reference slopes.
         ta = breflinetext(b, strcmp(refline, 'userfit'), interpreter);

         % labelrefline puts the head of the arrow on the line and the
         % text beside its tail. plotdqdt labels its late-time and
         % early-time lines through the same helper, so both figures
         % label a line alike.
         labelrefline(ax, a, b, ta, 'Style', labelstyle, ...
            'Color', labelcolor, 'FontSize', labelfontsize, ...
            'Interpreter', interpreter);

      case 'upperenvelope'

         % xtxt = exp(mean(log(xlim)));

         % place the label halfway across the x range, on the line. a is
         % 2/timestep, so a*xtxt^b holds the label on the line for any
         % timestep, not only the daily case where a is 2
         xlims = log10(xlim(ax));
         xtxt = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
         ytxt = a*xtxt^b;

         rotatedLogLogText(ax,xtxt,ytxt,'upper envelope',b, ...
            'FontSize',labelfontsize,'Color',labelcolor);

      case 'lowerenvelope'
         % for now, add this after the fact
         %
         %          xlims    = log10(xlim);
         %          xtxt     = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
         %          ytxt     = 2*xtxt;
   end
end

%% INPUT PARSER
function [x, y, mask, refline, refslope, userab, labels, refqtls, plotline, ...
      linecolor, labelcolor, labelfontsize, labelstyle, precision, ...
      timestep, ax] = parseinputs(x, y, varargin)

   % The label styles addlabels can draw, with the default first. The parser
   % validates against this list, and validatestring returns the member that
   % addlabels switches on.
   labelstyles = {'arrow', 'line'};

   % The MATLAB factory axes font size. A startup file can raise the axes
   % font size, so the labels take their size from this value instead.
   defaultfontsize = 10;

   parser = inputParser;
   parser.FunctionName = 'baseflow.plotrefline';

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
   parser.addParameter('labelcolor', [], @islabelcolor);
   parser.addParameter('labelfontsize', defaultfontsize, @(x) isnumericscalar(x) && x > 0);
   parser.addParameter('labelstyle', labelstyles{1}, ...
      @(style) any(validatestring(style, labelstyles)));
   parser.addParameter('precision', 1, @isnumeric); % default = 1 m3/s
   parser.addParameter('timestep', 1, @isnumeric); % default = 1 day
   parser.addParameter('ax', emptyaxes(), @isaxis);

   parser.parse(x, y, varargin{:});

   mask        = parser.Results.mask;
   refline     = parser.Results.refline;
   refslope    = parser.Results.refslope;
   userab      = parser.Results.userab;
   labels      = parser.Results.labels;
   refqtls     = parser.Results.refqtls;
   plotline    = parser.Results.plotline;
   linecolor   = parser.Results.linecolor;
   labelcolor  = parser.Results.labelcolor;
   labelfontsize = parser.Results.labelfontsize;
   labelstyle  = validatestring(parser.Results.labelstyle, labelstyles);
   precision   = parser.Results.precision;
   timestep    = parser.Results.timestep;
   ax          = parser.Results.ax;

   % An empty labelcolor means the caller stated no preference. Match the
   % line, so the label and its line read as one object in any figure theme.
   if isempty(labelcolor)
      labelcolor = linecolor;
   end
end
