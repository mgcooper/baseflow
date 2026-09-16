function ht = rotatedLogLogText(ax, xtxt, ytxt, txt, b, varargin)
   %ROTATEDLOGLOGTEXT add rotated text label to log-log axis
   %
   %  ht = rotatedLogLogText(ax, xtxt, ytxt, txt, b) places the latex string
   %  txt at data coordinates (xtxt, ytxt) in axes ax, rotated to lie along a
   %  line of slope b. Both scales of ax must be log. Trailing arguments pass
   %  through to the text function.
   %
   %  The rotation is the drawn angle of the line, which loglogangle computes
   %  from the axes size in pixels and the axis limits. A listener recomputes
   %  the angle on each redraw, so the label stays on the line after a
   %  resize, a zoom, a pan, or a limit change. A figure saved with savefig
   %  loses the listener, and the reopened label keeps its saved angle.
   %
   % See also: loglogangle, plotrefline, text

   % https://stackoverflow.com/questions/52928360/rotating-text-onto-a-line-on-a-log-scale-in-matplotlib

   ht = text(ax,xtxt,ytxt,txt,            ...
      'HorizontalAlignment','center',     ...
      'VerticalAlignment', 'bottom',      ...
      'FontSize',12,                      ...
      'Rotation',loglogangle(ax,b),       ...
      'Interpreter','latex',              ...
      varargin{:} ...
      );

   % Octave has no MarkedClean event, so the label keeps the angle it was
   % drawn with. Octave figures in this toolbox are exported at the size
   % they were drawn at.
   if isoctave
      return
   end

   % Recompute the angle on each redraw. The listener belongs to the axes,
   % so the axes deletes it. Holding the listener object on the label
   % instead puts a listener in the saved figure file, and openfig warns
   % that it cannot load one.
   addlistener(ax, 'MarkedClean', @(~, ~) updaterotation(ht, ax, b));
end

function updaterotation(ht, ax, b)
   %UPDATEROTATION reset the label rotation to the drawn angle of slope b

   % The axes outlives its labels, and a figure close deletes the label and
   % the axes in an order this callback does not control.
   if ~isvalid(ht) || ~isvalid(ax)
      return
   end

   % loglogangle errors on a linear scale. Keep the drawn angle instead, so
   % a scale change does not make the redraw error.
   if ~strcmp(get(ax, 'XScale'), 'log') || ~strcmp(get(ax, 'YScale'), 'log')
      return
   end

   theta = loglogangle(ax, b);

   % Setting Rotation marks the axes dirty again. Write only on a real
   % change, so the callback does not re-enter itself without end.
   if abs(get(ht, 'Rotation') - theta) > 0.01
      set(ht, 'Rotation', theta);
   end
end
