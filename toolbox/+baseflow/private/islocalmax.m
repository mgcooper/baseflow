function tf = islocalmax(X)
   %ISLOCALMAX Return true for local maximum indices of X.
   %
   %  tf = islocalmax(X) returns a logical array the size of X that is true
   %  at the local maxima found by baseflow.deps.peakfinder. The peakfinder
   %  call excludes the endpoints.

   % baseflow.deps.peakfinder(X,sel=0,threshold=0,max=true,includeendpoints=false);
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,0,1,false)) = true;
end