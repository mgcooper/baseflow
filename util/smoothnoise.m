function q = smoothflow(q)
% smooth measurement noise
   inan  = isnan(q);
   q     = smoothdata(q,'sgolay');
   q     = setnan(q,inan);