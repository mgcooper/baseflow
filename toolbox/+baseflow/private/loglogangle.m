function theta = loglogangle(ax, b)
   %LOGLOGANGLE Drawn angle of a log-log line of slope b.
   %
   % Syntax
   %
   %     theta = loglogangle(ax, b)
   %
   % Description
   %
   %     theta = loglogangle(ax, b) returns the angle in degrees between the
   %     horizontal and a line of slope b, as the line is drawn in axes ax.
   %     Both scales of ax must be log. The function errors on a linear
   %     scale. b is the exponent of the power law y = a*x^b, and a linear
   %     axis has no decades to measure the rise against.
   %
   %     One decade spans axpos(3)/ndecx pixels in x and axpos(4)/ndecy
   %     pixels in y. axpos is the axes box in pixels, ndecx is the number
   %     of decades in XLim, and ndecy is the number of decades in YLim.
   %     The drawn angle therefore depends on the size of the axes and on
   %     the axis limits, not on b alone.
   %
   % See also: rotatedLogLogText, axespixelbox, plotrefline

   % b is a power-law exponent, so both scales must be log for the rise to
   % be b decades of y per decade of x.
   if ~strcmp(get(ax, 'XScale'), 'log') || ~strcmp(get(ax, 'YScale'), 'log')
      error('baseflow:loglogangle:scaleNotLog', ...
         'ax must use a log scale on both the x axis and the y axis')
   end

   % The drawn plot box in pixels. drawarrow measures its head against the
   % same box, so a label and the arrow beside it follow one geometry.
   axpos = axespixelbox(ax);

   xlims = log10(get(ax, 'XLim'));
   ylims = log10(get(ax, 'YLim'));

   % Pixels per decade on each axis.
   dxdec = axpos(3) / (xlims(2) - xlims(1));
   dydec = axpos(4) / (ylims(2) - ylims(1));

   % b multiplies the rise inside the arctangent, not the angle outside it.
   % A line of slope b rises b decades of y over one decade of x.
   theta = atan2d(b * dydec, dxdec);
end
