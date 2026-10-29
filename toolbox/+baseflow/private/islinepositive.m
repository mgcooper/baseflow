function tf = islinepositive(y, ey)
   %ISLINEPOSITIVE Return true if linear fit to input X has positive slope.
   %
   %  tf = islinepositive(y) fits a straight line to y against its index
   %  and returns true when the fitted slope is positive.
   %
   %  tf = islinepositive(y, ey) takes ey, a bound on the rounding error
   %  of each value of y. It returns true only when the trend is positive
   %  beyond its rounding error (see trendsign), so a constant stretch,
   %  whose trend is zero in exact arithmetic, is not rising.
   %
   %  See also: trendsign, islineconvex

   % Without a rounding bound, keep the least-squares slope sign.
   if nargin < 2
      ab = [ones(size(y)), (1:numel(y))'] \ y;
      tf = ab(2) > 0;
      return
   end

   % With a bound, the trend must be positive beyond its rounding.
   tf = trendsign(y, ey) > 0;
end
