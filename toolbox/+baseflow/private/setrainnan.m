function q = setrainnan(q,r,rmin)
   %SETRAINNAN Set rain data exceeding threshold RMIN nan.
   %
   %  q = setrainnan(q, r, rmin) sets q nan where the rain r exceeds rmin,
   %  including the elements directly before and after each exceedance.
   %  Note: no toolbox function calls it.
   irain = find(r > rmin);
   irain = unique([irain; irain+1; irain-1]);

   % Keep the neighbor indices inside q. The last sample is a valid index.
   irain = irain(irain > 0);
   irain = irain(irain <= numel(q));
   inan  = false(size(q)); inan(irain) = true;

   % setnan takes the logical mask as its third input, after the nanval.
   q = setnan(q, [], inan);
end
