function fig = sizefigure(fig)
   %SIZEFIGURE Size a point-cloud figure and keep the position it was given.
   %
   % Syntax
   %
   %     fig = sizefigure(fig)
   %
   % Description
   %
   %     fig = sizefigure(fig) sets the width and height of the figure fig
   %     and returns it. A fixed position such as [0 0] or [1 1] puts the
   %     window in the bottom-left corner of the screen, where the dock
   %     covers the axis labels, so only the size belongs here.
   %
   %     pointcloudplot and plotdqdt draw the same kind of figure, so both
   %     take their size from this function.
   %
   % See also: pointcloudplot, plotdqdt

   % Width and height in points. The axis labels of a log-log point cloud
   % need this much room.
   figuresize = [640 600];

   figureposition = get(fig, 'Position');
   set(fig, 'Position', [figureposition(1:2) figuresize]);
end
