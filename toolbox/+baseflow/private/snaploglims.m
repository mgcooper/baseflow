function lims = snaploglims(lims, pad, axislimits)
   %SNAPLOGLIMS Widen log-axis limits to the enclosing decade when it is near.
   %
   % Syntax
   %
   %     lims = snaploglims(lims, pad, axislimits)
   %
   % Description
   %
   %     lims = snaploglims(lims, pad, axislimits) moves each limit out to
   %     the enclosing decade when that decade is nearer than the tolerance
   %     axislimits sets, so the axis corner carries a tick. A limit farther
   %     from its decade than the tolerance keeps the multiplicative padding
   %     in pad, so data that ends mid-decade gains no empty decade.
   %
   % Required inputs
   %
   %     lims = 1x2 double of axis limits, [low high]
   %     pad = 1x2 double of low and high multipliers. A limit that does not
   %           snap is multiplied by its element of pad.
   %     axislimits = char, one of 'snap', 'decades', or 'none'. 'snap'
   %           snaps a limit that lies within a quarter decade of its
   %           decade. 'decades' snaps every limit. 'none' snaps no limit,
   %           so every limit takes its padding.
   %
   % Output
   %
   %     lims = 1x2 double of widened limits
   %
   % See also: setlogticks, pointcloudplot, plotdqdt

   % Map the policy to the largest gap, in decades, that still snaps a limit
   % out to its decade. The comparisons below are strict, so a tolerance of
   % zero pads every limit and returns the limits the data sets.
   switch axislimits
      case 'snap'
         tol = 0.25;
      case 'decades'
         tol = 1;
      case 'none'
         tol = 0;
      otherwise
         error('baseflow:snaploglims:unknownAxisLimits', ...
            'axislimits must be snap, decades, or none')
   end

   % Zero, a negative value, and a non-finite value have no log10, so the
   % caller keeps the limits it already has.
   if any(~isfinite(lims)) || any(lims <= 0)
      return
   end

   % Work in decades so the test is the same at both ends of the axis.
   lo = log10(lims(1));
   hi = log10(lims(2));

   % Move the low end down to its decade when that decade is near.
   if lo - floor(lo) < tol
      lims(1) = 10^floor(lo);
   else
      lims(1) = lims(1) * pad(1);
   end

   % Move the high end up to its decade when that decade is near.
   if ceil(hi) - hi < tol
      lims(2) = 10^ceil(hi);
   else
      lims(2) = lims(2) * pad(2);
   end
end
