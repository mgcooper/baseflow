function verifydecadeticks(testCase, ax, axname)
   %VERIFYDECADETICKS Verify every decade inside the axis limits has a tick.
   %
   %  verifydecadeticks(testCase, ax, axname) fails testCase when a decade
   %  that lies inside the limits of the named axis of ax carries no tick.
   %  axname is 'X' or 'Y'. A reference line sets the ticks from the limits
   %  that are current when the line is drawn, so a limit set after that can
   %  add a decade the ticks do not cover.
   %
   %  setlogticks thins the ticks of an axis that spans about ten decades or
   %  more, so this check applies to a shorter axis. It passes an axis with
   %  a wider span, because the thinned list is not one tick per decade.
   %
   % See also: setlogticks, test_pointcloudplot, test_plotdqdt

   lims = get(ax, [axname 'Lim']);
   ticks = get(ax, [axname 'Tick']);

   % setlogticks keeps one tick per decade only up to this span.
   maxdecades = 10;
   if log10(lims(2)) - log10(lims(1)) >= maxdecades
      return
   end

   % 10^k for every whole k the limits reach, then keep the decades the
   % axis box encloses. A decade on a limit is on the axis edge, where a
   % tick is optional.
   decades = 10 .^ (ceil(log10(lims(1))):fix(log10(lims(2))));
   decades = decades(decades > lims(1) & decades < lims(2));

   missing = decades(~ismember(decades, ticks));
   testCase.verifyEmpty(missing, sprintf( ...
      'The %s axis has no tick at %s', axname, mat2str(missing, 6)))
end
