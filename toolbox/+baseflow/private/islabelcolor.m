function tf = islabelcolor(color)
   %ISLABELCOLOR Return true for a value the graphics Color property takes.
   %
   % Syntax
   %
   %     tf = islabelcolor(color)
   %
   % Description
   %
   %     tf = islabelcolor(color) returns true when color is an RGB triplet
   %     with values in [0, 1], a color name such as 'k' or "black", or
   %     empty. A plotting function takes empty as a request for its
   %     default color.
   %
   % See also: plotrefline, plotdqdt

   % The graphics Color property takes a triplet or a name, so accept both
   % and let the graphics call reject an unknown name.
   tf = isempty(color) || ischar(color) || isstring(color) || ...
      (isnumeric(color) && numel(color) == 3 && all(color >= 0) && ...
      all(color <= 1));
end
