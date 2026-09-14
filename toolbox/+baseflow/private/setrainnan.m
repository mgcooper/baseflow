function q = setrainnan(q,r,rmin)
   %SETRAINNAN Set rain data exceeding threshold RMIN nan.
   %
   %  q = setrainnan(q, r, rmin) is meant to set q nan where the rain r
   %  exceeds rmin, including the elements directly before and after each
   %  exceedance. Note: no toolbox function calls it. The setnan call
   %  passes the mask as the nanval input and errors, and the code drops an
   %  exceedance on the last sample.
   irain = find(r > rmin);
   irain = unique([irain; irain+1; irain-1]);
   irain = irain(irain > 0);
   irain = irain(irain < numel(q));
   inan  = false(size(q)); inan(irain) = true;
   q = setnan(q, inan);
end
