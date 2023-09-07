function [t, q, r, ei] = rmtrailingnans(t, q, r)
   %RMTRAILINGNANS Remove trailing nans.
   
   if nargin == 2
      r = nan(size(q));
   end

   tf = flipud(logical(cumprod(isnan(flipud(q))))); % trailing nans
   ei = find(tf == false, 1, 'last'); % last non-nan indici

   t(tf) = [];
   q(tf) = [];
   r(tf) = [];
end