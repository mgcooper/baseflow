function tf = islocalmax(X, sel)
   %ISLOCALMAX Return true for local maximum indices of X.
   %
   %  tf = islocalmax(X) returns a logical array the size of X that is true
   %  at the local maxima found by baseflow.deps.peakfinder. The peakfinder
   %  call excludes the endpoints and applies no threshold. On signals
   %  without flat runs, the result matches the MATLAB islocalmax function,
   %  which Octave does not have.
   %
   %  tf = islocalmax(X, sel) passes sel to peakfinder as the selectivity: a
   %  local maximum must differ from the neighbouring opposite extrema by
   %  more than sel, in the units of X. eventfinder passes its
   %  numerical-zero threshold, so rounding-size wiggles are not extrema.
   %
   %  See also: islocalmin

   % peakfinder(X,sel,threshold=[],extrema=1,includeendpoints=false)
   tf = false(size(X));
   % A selectivity of 0 keeps every sign change of the derivative.
   if nargin < 2
      sel = 0;
   end
   tf(baseflow.deps.peakfinder(X,sel,[],1,false)) = true;
end