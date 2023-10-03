function [normX, normY] = normalizeDataCoordinates(ax, x, y)
   %NORMALIZEDDATACOORDINATES Convert data coordinates to normalized coordinates
   %
   %   [normX, normY] = normalizeDataCoordinates(ax, x, y) converts data
   %   coordinates (x, y) in axes 'ax' to normalized coordinates with respect to
   %   the figure containing the axes. The function supports both linear and
   %   logarithmic axes scales. The output normX and normY are the x and y
   %   coordinates in normalized units.
   %
   %   Input:
   %       ax - handle to axes object
   %       x  - x coordinate in data units
   %       y  - y coordinate in data units
   %
   %   Output:
   %       normX - x coordinate in normalized figure units
   %       normY - y coordinate in normalized figure units
   %
   %   Example:
   %       ax = gca;
   %       [normX, normY] = normalizeDataCoordinates(ax, 2, 4);
   %
   %   See also: axes, plotboxpos

   % Validate input
   if ~ishandle(ax) || ~strcmp(get(ax, 'Type'), 'axes')
      error('Input ax must be an axes handle.');
   end
   if ~isnumeric(x) || ~isnumeric(y)
      error('x and y must be numeric.');
   end

   % Store old units
   oldUnits = ax.Units;

   % Set axes units to normalized for calculation
   ax.Units = 'normalized';

   % Fetch position and limits
   ax_pos = plotboxpos(ax);
   x_lim = ax.XLim;
   y_lim = ax.YLim;

   % Handle log-scaled axes
   if strcmp(ax.XScale, 'log')
      x = log10(x);
      x_lim = log10(x_lim);
   end
   if strcmp(ax.YScale, 'log')
      y = log10(y);
      y_lim = log10(y_lim);
   end

   % Perform the conversion
   normX = ax_pos(1) + (x - x_lim(1)) ./ (x_lim(2) - x_lim(1)) .* ax_pos(3);
   normY = ax_pos(2) + (y - y_lim(1)) ./ (y_lim(2) - y_lim(1)) .* ax_pos(4);

   % Revert to old units
   ax.Units = oldUnits;
end
