function labelrefline(ax, a, b, txt, varargin)
   %LABELREFLINE Label the reference line -dQ/dt = a*Q^b.
   %
   % Syntax
   %
   %     labelrefline(ax, a, b, txt)
   %     labelrefline(ax, a, b, txt, 'Style', style)
   %
   % Description
   %
   %     labelrefline(ax, a, b, txt) points an arrow at the line
   %     -dQ/dt = a*Q^b in the axes ax and writes txt beside the tail of
   %     the arrow. The head sits on the line, above the bottom of the
   %     axes, and labelanchor raises it when the line reaches that height
   %     left of the axes.
   %
   %     labelrefline(ax, a, b, txt, 'Style', 'line') writes txt along the
   %     line, at the angle the line is drawn, and draws no arrow.
   %
   % Optional name-value inputs
   %
   %     Style       = 'arrow' (default) or 'line'
   %     Color       = color of the arrow and the text. Default black.
   %     FontSize    = font size of the text. Default 10.
   %     Interpreter = text interpreter. Default 'latex'.
   %
   %     The arrow reads a MATLAB-only axes property, so the 'arrow' style
   %     draws neither arrow nor text on Octave. The 'line' style draws in
   %     both languages.
   %
   % See also: plotrefline, plotdqdt, labelanchor, rotatedLogLogText

   % The arrow tail spans this fraction of the drawn x decades. A longer
   % tail reads as a rule across the axes instead of as an arrow.
   tailfraction = 1/25;

   % The text starts this far right of the tail, as a share of the tail,
   % so the label does not touch the arrow.
   textgap = 0.15;

   % The head starts this fraction of the way up the y decades. labelanchor
   % raises it when the label would start left of the axes.
   anchorfactor = 20;

   [style, color, fontsize, interpreter] = parseinputs(varargin{:});

   xlims = xlim(ax);
   ylims = ylim(ax);
   ndecsx = log10(xlims(2)) - log10(xlims(1));

   % Put the head on the line and the tail to its right, at the same height.
   [xhead, yhead] = labelanchor(a, b, xlims, ylims, anchorfactor);
   xtail = 10^(log10(xhead) + ndecsx * tailfraction);
   xtext = 10^(log10(xhead) + ndecsx * tailfraction * (1 + textgap));

   switch style

      case 'line'
         % Write the text where the arrow style writes it, lifted onto the
         % line. rotatedLogLogText turns it to the drawn angle of the line.
         rotatedLogLogText(ax, xtext, a * xtext^b, txt, b, ...
            'FontSize', fontsize, 'Color', color, ...
            'Interpreter', interpreter);

      case 'arrow'
         % The vendored arrow reads a MATLAB-only axes property.
         if isoctave
            return
         end

         % arrow draws in the current axes of the current figure, so make
         % both current for the call, then give the caller its current
         % figure and current axes back.
         fig = ancestor(ax, 'figure');
         currentfig = get(groot, 'CurrentFigure');
         currentax = get(fig, 'CurrentAxes');
         restorefig = onCleanup(@() set(groot, 'CurrentFigure', currentfig));
         restoreax = onCleanup(@() set(fig, 'CurrentAxes', currentax));
         set(groot, 'CurrentFigure', fig);
         set(fig, 'CurrentAxes', ax);

         % Set the color of the arrow patch and of the text. Without an
         % explicit color the text ColorMode stays auto, and a dark figure
         % theme draws the label light grey while the line keeps its color.
         baseflow.deps.arrow([xtail, yhead], [xhead, yhead], ...
            'BaseAngle', 90, 'Length', 8, 'TipAngle', 10, ...
            'EdgeColor', color, 'FaceColor', color);
         text(ax, xtext, yhead, txt, ...
            'HorizontalAlignment', 'left', 'FontSize', fontsize, ...
            'Color', color, 'Interpreter', interpreter);
   end
end

%% INPUT PARSER
function [style, color, fontsize, interpreter] = parseinputs(varargin)

   % The label styles this function draws, with the default first.
   styles = {'arrow', 'line'};

   parser = inputParser;
   parser.FunctionName = 'labelrefline';
   parser.addParameter('Style', styles{1}, ...
      @(value) any(validatestring(value, styles)));
   parser.addParameter('Color', [0 0 0], @islabelcolor);
   parser.addParameter('FontSize', 10, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('Interpreter', 'latex', @ischarlike);
   parser.parse(varargin{:});

   style = validatestring(parser.Results.Style, styles);
   color = parser.Results.Color;
   fontsize = parser.Results.FontSize;
   interpreter = parser.Results.Interpreter;

   % An empty color asks for the default.
   if isempty(color)
      color = [0 0 0];
   end
end
