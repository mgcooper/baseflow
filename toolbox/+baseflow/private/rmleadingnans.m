function [t,q,r,si] = rmleadingnans(t,q,r)
   %RMLEADINGNANS Remove leading nans.
   if nargin == 2
      r = nan(size(q));
   end

   tf = logical(cumprod(isnan(q(:))));   % consecutive leading nans true
   si = find(tf==false,1,'first');    % first non-nan indici
   
   t(tf) = [];
   q(tf) = [];
   r(tf) = [];
end
