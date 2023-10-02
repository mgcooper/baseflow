function [y,win] = smoothflow(x)
   %SMOOTHFLOW Smooth measurement noise.
   
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

