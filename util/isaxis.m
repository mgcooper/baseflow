function tf = isaxis(ax)
%ISAXIS logical check if axis object
tf = false;
if isa(ax,'matlab.graphics.axis.Axes')
   tf = true;
end