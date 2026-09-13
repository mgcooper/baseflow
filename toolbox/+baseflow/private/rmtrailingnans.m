function [t, q, r, ei] = rmtrailingnans(t, q, r)
   %RMTRAILINGNANS Remove trailing nans.
   %
   %  [t, q, r, ei] = rmtrailingnans(t, q, r) removes the trailing nan run
   %  of q from t, q, and r. ei is the index of the last non-nan value in
   %  the original q. If the call omits r, the function sets r to a nan
   %  vector the size of q.
   
   if nargin == 2
      r = nan(size(q));
   end

   tf = flipud(logical(cumprod(isnan(flipud(q(:)))))); % trailing nans
   ei = find(tf == false, 1, 'last'); % last non-nan indici

   t(tf) = [];
   q(tf) = [];
   r(tf) = [];
end