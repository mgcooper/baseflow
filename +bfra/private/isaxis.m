function tf = isaxis(ax)
%ISAXIS logical check if axis object
if isoctave
   tf = isaxes(ax);
else
   tf = isa(ax,'matlab.graphics.axis.Axes');
end
