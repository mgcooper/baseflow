function tf = islocalmax(X)

   % bfra.deps.peakfinder(X,sel=0,threshold=0,max=true,includeendpoints=false);
   tf = false(size(X));
   tf(bfra.deps.peakfinder(X,0,0,1,false)) = true;
end