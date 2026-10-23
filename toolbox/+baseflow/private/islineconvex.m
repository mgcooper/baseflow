function tf = islineconvex(y, ey)
   %ISLINECONVEX True if the first differences of Y trend downward (concave down).
   %
   %  tf = islineconvex(y) fits a straight line to the first differences of
   %  y against their index and returns true when the fitted slope is
   %  negative.
   %
   %  tf = islineconvex(y, ey) takes ey, a bound on the rounding error of
   %  each value of y. Each first difference then carries at most 2*ey. It
   %  returns true only when the trend is negative beyond its rounding
   %  error (see trendsign), so a straight stretch, whose first
   %  differences have a zero trend in exact arithmetic, is not convex.
   %
   %  See also: trendsign, islinepositive
   dy = diff(y);

   % Without a rounding bound, keep the least-squares slope sign.
   if nargin < 2
      ab = [ones(size(dy)), (1:numel(dy))'] \ dy;
      tf = ab(2) < 0;
      return
   end

   % With a bound, the trend must be negative beyond its rounding.
   tf = trendsign(dy, 2*ey) < 0;
end
