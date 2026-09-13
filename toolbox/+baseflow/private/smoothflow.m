function [y,win] = smoothflow(x)
   %SMOOTHFLOW Smooth measurement noise.
   %
   %  [y, win] = smoothflow(x) smooths x with a Savitzky-Golay filter
   %  (smoothdata 'sgolay') and returns the smoothed data y and the window
   %  size win. Nan elements of x stay nan in y, and the function sets
   %  negative smoothed values to zero. In Octave, a moving mean with an odd
   %  window no larger than 7 replaces the Savitzky-Golay filter.
   
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
end

