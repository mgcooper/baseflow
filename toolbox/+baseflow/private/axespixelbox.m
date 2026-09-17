function axpos = axespixelbox(ax)
   %AXESPIXELBOX The drawn plot box of an axes, in pixels.
   %
   % Syntax
   %
   %     axpos = axespixelbox(ax)
   %
   % Description
   %
   %     axpos = axespixelbox(ax) returns [left bottom width height] of the
   %     box the axes ax draws in, in pixels. The pixel box carries the
   %     figure aspect ratio, which a normalized box drops, so an angle or
   %     a length measured on the screen needs this box.
   %
   %     With an automatic aspect ratio, the drawn box is the axes
   %     Position, which getpixelposition reads without touching the axes.
   %     A manual aspect ratio, as axis square and axis equal set, draws a
   %     smaller box inside that Position, so read that box with plotboxpos
   %     and restore the units of the caller. Setting Units marks the axes
   %     dirty, so this function does it only when the axes needs it.
   %
   % See also: loglogangle, drawarrow, plotboxpos

   ismanual = strcmp(get(ax, 'DataAspectRatioMode'), 'manual') ...
      || strcmp(get(ax, 'PlotBoxAspectRatioMode'), 'manual');

   if ismanual
      axunits = get(ax, 'Units');
      restoreunits = onCleanup(@() set(ax, 'Units', axunits));
      set(ax, 'Units', 'pixels');
      axpos = baseflow.deps.plotboxpos(ax);
   else
      axpos = getpixelposition(ax);
   end
end
