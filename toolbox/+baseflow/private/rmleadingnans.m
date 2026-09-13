function [t,q,r,si] = rmleadingnans(t,q,r)
   %RMLEADINGNANS Remove leading nans.
   %
   %  [t, q, r, si] = rmleadingnans(t, q, r) removes the leading nan run of
   %  q from t, q, and r. si is the index of the first non-nan value in the
   %  original q. If the call omits r, the function sets r to a nan vector
   %  the size of q.
   if nargin == 2
      r = nan(size(q));
   end

   tf = logical(cumprod(isnan(q(:))));   % consecutive leading nans true
   si = find(tf==false,1,'first');    % first non-nan indici

   t(tf) = [];
   q(tf) = [];
   r(tf) = [];
end

