function tf = isaxis(ax)

% % based on plot.m functionsignature file, might use these:
%    "type":[["matlab.graphics.axis.AbstractAxes"], ["matlab.ui.control.UIAxes"]]},
   
   tf = false;
   if isa(ax,'matlab.graphics.axis.Axes')
      tf = true;
   end
   
%    % for reference, this was my first thought, didn't know about 'isa'
%    if strcmp(class(ax),'matlab.graphics.axis.Axes')
%       tf = true;
%    end