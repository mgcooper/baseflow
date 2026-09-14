function tf = islocalmax(X)
   %ISLOCALMAX Return true for local maximum indices of X.
   %
   %  tf = islocalmax(X) returns a logical array the size of X that is true
   %  at the local maxima found by baseflow.deps.peakfinder. The peakfinder
   %  call excludes the endpoints and applies no threshold. On signals
   %  without flat runs, the result matches the MATLAB islocalmax function,
   %  which Octave does not have.
   %
   %  See also: islocalmin

   % peakfinder(X,sel=0,threshold=[],extrema=1,includeendpoints=false)
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,[],1,false)) = true;
end