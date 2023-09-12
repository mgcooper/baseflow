function tf = islocalmax(X)
   %ISLOCALMAX Return true for local maximum indices of X.

   % baseflow.deps.peakfinder(X,sel=0,threshold=0,max=true,includeendpoints=false);
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,0,1,false)) = true;
end