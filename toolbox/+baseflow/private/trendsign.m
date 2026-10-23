function sg = trendsign(y, ey)
   %TRENDSIGN Sign of the least-squares trend of Y beyond its rounding.
   %
   %  sg = trendsign(y, ey) returns 1 or -1 when the least-squares slope of
   %  y against its index is positive or negative by more than its
   %  rounding error, and 0 otherwise. ey bounds the rounding error of each
   %  value of y.
   %
   %  The slope has the sign of its numerator N = sum((k - kbar).*y),
   %  because its denominator is positive. k - kbar is exact for the index
   %  k. N carries at most sum(abs(k - kbar))*ey from the values of y, and
   %  the sum rounds by at most L*u*sum(abs(k - kbar))*max(abs(y)), with
   %  L = numel(y) and u = eps/2.
   %
   %  See also: islineconvex, islinepositive

   % The centred index makes the numerator carry the slope sign.
   y = y(:);
   L = numel(y);
   k = (1:L)' - (L + 1)/2;
   N = sum(k .* y);

   % A trend counts only beyond the rounding bound of its numerator.
   tol = sum(abs(k)) * (ey + L * (eps/2) * max(abs(y)));
   sg = (N > tol) - (N < -tol);
end
