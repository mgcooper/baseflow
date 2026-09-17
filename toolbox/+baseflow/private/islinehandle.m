function tf = islinehandle(h)
   %ISLINEHANDLE Return true for a graphics handle of a plotted line.
   %
   % Syntax
   %
   %     tf = islinehandle(h)
   %
   % Description
   %
   %     tf = islinehandle(h) returns true when h holds graphics handles of
   %     plotted lines. MATLAB returns a graphics object from plot and
   %     Octave returns a numeric handle, so accept both. The plotting
   %     functions set a handle to nan when they draw no line, and nan is
   %     numeric but not a graphics handle, so it returns false.
   %
   % See also: plotdqdt, pointcloudplot, formatPlotMarkers

   % ishghandle takes the numeric form in both languages, and isobject
   % takes the MATLAB graphics object, which ishghandle also accepts.
   tf = isobject(h) || (isnumeric(h) && ~isempty(h) && all(ishghandle(h(:))));
end
