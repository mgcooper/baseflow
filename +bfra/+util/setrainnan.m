function q = setrainnan(q,r,rmin)
irain = find(r>rmin);
irain = unique([irain;irain+1;irain-1]);
irain = irain(irain>0); irain = irain(irain<numel(q));
inan  = false(size(q)); inan(irain) = true;
q     = bfra.util.setnan(q,inan);