function tf = islocalmin(X)
   %ISLOCALMIN Return true for local minimum indices of X.
   %
   %  tf = islocalmin(X) returns a logical array the size of X that is true
   %  at the local minima found by baseflow.deps.peakfinder. The peakfinder
   %  call excludes the endpoints and applies no threshold. On signals
   %  without flat runs, the result matches the MATLAB islocalmin function,
   %  which Octave does not have.
   %
   %  See also: islocalmax

   % peakfinder(X,sel=0,threshold=[],extrema=-1,includeendpoints=false)
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,[],-1,false)) = true;
end
