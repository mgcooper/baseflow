function tf = isaxis(ax)
   %ISAXIS logical check if axis object
   %
   %  tf = isaxis(ax) returns true if ax is a matlab.graphics.axis.Axes
   %  object. In Octave, isaxes does the test.
   if isoctave
      tf = isaxes(ax);
   else
      tf = isa(ax,'matlab.graphics.axis.Axes');
   end
end
