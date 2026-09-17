function relayoutloglogtext(ax)
   %RELAYOUTLOGLOGTEXT Reset the angle of every rotated log-log label.
   %
   % Syntax
   %
   %     relayoutloglogtext(ax)
   %
   % Description
   %
   %     relayoutloglogtext(ax) resets the rotation of every label that
   %     rotatedLogLogText drew in the axes ax, to the drawn angle of the
   %     line each label names. A caller that sets the final axis limits
   %     after it draws the labels calls this function, because the angle
   %     of a line on a log-log plot follows the limits.
   %
   %     MATLAB recomputes the angle through a listener on each redraw.
   %     Octave has no MarkedClean event, so this function is what keeps an
   %     Octave label on its line.
   %
   % See also: rotatedLogLogText, loglogangle, pointcloudplot, plotdqdt

   % loglogangle needs both scales log.
   if ~strcmp(get(ax, 'XScale'), 'log') || ~strcmp(get(ax, 'YScale'), 'log')
      return
   end

   % rotatedLogLogText tags each label it draws and keeps the slope of the
   % line in UserData.
   labels = findobj(ax, 'Type', 'text', 'Tag', 'loglogslope');

   for n = 1:numel(labels)
      set(labels(n), 'Rotation', loglogangle(ax, get(labels(n), 'UserData')));
   end
end
