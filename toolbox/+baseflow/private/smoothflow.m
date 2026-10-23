function [y,win,err] = smoothflow(x)
   %SMOOTHFLOW Smooth measurement noise.
   %
   %  [y, win] = smoothflow(x) smooths x with a Savitzky-Golay filter
   %  (smoothdata 'sgolay') and returns the smoothed data y and the window
   %  size win. Nan elements of x stay nan in y, and the function sets
   %  negative smoothed values to zero. In Octave, a moving mean with an odd
   %  window no larger than 7 replaces the Savitzky-Golay filter.
   %
   %  [y, win, err] = smoothflow(x) also returns err, a bound on the
   %  rounding error of each value of y, in the units of x. A smoothed
   %  value is a dot product of win weights with the data, so it rounds by
   %  at most win*u*W*s, and the rounding of the data adds W*u*s. Here
   %  u = eps/2, s = max(abs(x)), and W = 2.25 bounds the sum of absolute
   %  quadratic Savitzky-Golay weights for any window, edge rows included.
   %  The moving mean has weights that sum to 1, so the same bound holds.
   %  eventfinder takes err as its 'qerror' option.
   
   % This is only needed when testing smooth in matlab
   % warnstate = warning;
   % cleanupObj = onCleanup(@() warning(warnstate));
   % warning('off', 'MATLAB:polyfit:PolyNotUnique');
   
   if isoctave
      
      win = min(7, max(3, 2*floor((numel(x)/5+1)/2) - 1));
      y = nanmovmean(x, win);
      %y = smooth(x, win, 'sgolay'); y = y(:);
         
   else
      [y, win] = smoothdata(x, 'sgolay');
   end
   y = setnan(y,[],isnan(x));
   y(y<0)=0;

   % The rounding bound of the smoothed values (see the help above).
   W = 2.25;
   err = W * (max(win) + 1) * (eps/2) * max(abs(x(isfinite(x))));
   if isempty(err)
      err = 0;
   end
end

