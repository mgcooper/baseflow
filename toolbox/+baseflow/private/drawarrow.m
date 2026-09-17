function harrow = drawarrow(ax, tail, head, varargin)
   %DRAWARROW Draw an arrow in an axes, with the head on a given point.
   %
   % Syntax
   %
   %     harrow = drawarrow(ax, tail, head)
   %     harrow = drawarrow(ax, tail, head, 'Color', color)
   %
   % Description
   %
   %     harrow = drawarrow(ax, tail, head) draws an arrow in the axes ax,
   %     with its point at head and its shaft starting at tail. Both are
   %     [x y] in data units. harrow holds the shaft line and the head
   %     patch, in that order.
   %
   %     The head is a triangle of a fixed size in pixels, so it keeps its
   %     shape whatever the axis limits are, and a log axis draws the same
   %     head as a linear one. The shaft and the head are built in pixels
   %     from the drawn plot box, then converted back to data units.
   %
   %     Note: the head size in data units follows the size of the axes
   %     when the arrow is drawn. A later resize leaves the head at the
   %     size it was given.
   %
   %     A log axis cannot show a value at or below zero, so an arrow with
   %     such an endpoint draws nothing and raises
   %     baseflow:drawarrow:nonpositiveLogCoordinate.
   %
   % Optional name-value inputs
   %
   %     Color     = color of the shaft and the head. Default black.
   %     Length    = length of the head in pixels. Default 8.
   %     TipAngle  = half angle of the head in degrees. Default 10.
   %     LineWidth = width of the shaft. Default 1.
   %
   % See also: labelrefline, axespixelbox, plotrefline, plotdqdt

   [color, headlength, tipangle, linewidth] = parseinputs(varargin{:});

   % The drawn box carries the figure aspect ratio, so the head is the same
   % shape in x and in y.
   axpos = axespixelbox(ax);
   xlims = get(ax, 'XLim');
   ylims = get(ax, 'YLim');
   xlog = strcmp(get(ax, 'XScale'), 'log');
   ylog = strcmp(get(ax, 'YScale'), 'log');

   % A log axis has no place for a value at or below zero. log10 of such a
   % value is complex, and a complex coordinate draws the arrow at the
   % value reflected through the origin, which names a point the data never
   % reaches. Draw nothing, and say so.
   if (xlog && any([tail(1) head(1)] <= 0)) ...
         || (ylog && any([tail(2) head(2)] <= 0))
      warning('baseflow:drawarrow:nonpositiveLogCoordinate', ...
         ['drawarrow drew no arrow: a log axis cannot show the point ' ...
         '(%g, %g) or the point (%g, %g).'], ...
         tail(1), tail(2), head(1), head(2));
      harrow = [];
      return
   end

   % Work in pixels measured from the lower-left corner of the box. The
   % corner offset cancels in every difference below, so leave it out.
   tailpix = [datatopixel(tail(1), xlims, xlog, axpos(3)), ...
      datatopixel(tail(2), ylims, ylog, axpos(4))];
   headpix = [datatopixel(head(1), xlims, xlog, axpos(3)), ...
      datatopixel(head(2), ylims, ylog, axpos(4))];

   % Unit vector from the point back along the shaft.
   shaft = tailpix - headpix;
   shaftlength = hypot(shaft(1), shaft(2));
   % A zero-length arrow has no direction to point in. Octave has no
   % gobjects, so return the empty array both languages take.
   if shaftlength == 0
      harrow = [];
      return
   end
   backward = shaft / shaftlength;

   % A head longer than the shaft leaves no shaft to draw, so keep the head
   % inside the arrow.
   headlength = min(headlength, 0.8 * shaftlength);

   % The base of the head sits headlength back from the point, and its two
   % corners sit either side of the shaft.
   basepix = headpix + headlength * backward;
   across = [-backward(2), backward(1)] * headlength * tand(tipangle);
   corner1 = basepix + across;
   corner2 = basepix - across;

   % Back to data units, for a shaft line and a head patch.
   shaftx = pixeltodata([tailpix(1) basepix(1)], xlims, xlog, axpos(3));
   shafty = pixeltodata([tailpix(2) basepix(2)], ylims, ylog, axpos(4));
   headx = pixeltodata([headpix(1) corner1(1) corner2(1)], ...
      xlims, xlog, axpos(3));
   heady = pixeltodata([headpix(2) corner1(2) corner2(2)], ...
      ylims, ylog, axpos(4));

   % Tag both parts, and hide them from the legend and from a caller that
   % collects the lines of the axes.
   hshaft = line(ax, shaftx, shafty, 'Color', color, ...
      'LineWidth', linewidth, 'Tag', 'refarrowshaft', ...
      'HandleVisibility', 'off');
   hhead = patch(ax, headx, heady, color, 'EdgeColor', color, ...
      'FaceColor', color, 'Tag', 'refarrowhead', 'HandleVisibility', 'off');

   harrow = [hshaft, hhead];
end

function pixel = datatopixel(value, lims, islog, npixels)
   % Position of a data value in the box, in pixels from its left or bottom
   % edge. A log axis measures the distance in decades.
   if islog
      value = log10(value);
      lims = log10(lims);
   end
   pixel = (value - lims(1)) ./ (lims(2) - lims(1)) .* npixels;
end

function value = pixeltodata(pixel, lims, islog, npixels)
   % The inverse of datatopixel.
   if islog
      lims = log10(lims);
   end
   value = lims(1) + pixel ./ npixels .* (lims(2) - lims(1));
   if islog
      value = 10.^value;
   end
end

%% INPUT PARSER
function [color, headlength, tipangle, linewidth] = parseinputs(varargin)

   % The head size in pixels, and the half angle at its point. A head of
   % this size reads as an arrow beside a label without covering the line
   % it points at.
   defaultheadlength = 8;
   defaulttipangle = 10;

   parser = inputParser;
   parser.FunctionName = 'drawarrow';
   parser.addParameter('Color', [0 0 0], @islabelcolor);
   parser.addParameter('Length', defaultheadlength, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.addParameter('TipAngle', defaulttipangle, ...
      @(value) isnumericscalar(value) && value > 0 && value < 90);
   parser.addParameter('LineWidth', 1, ...
      @(value) isnumericscalar(value) && value > 0);
   parser.parse(varargin{:});

   color = parser.Results.Color;
   headlength = parser.Results.Length;
   tipangle = parser.Results.TipAngle;
   linewidth = parser.Results.LineWidth;

   % An empty color asks for the default.
   if isempty(color)
      color = [0 0 0];
   end
end
