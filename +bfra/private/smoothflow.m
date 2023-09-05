function [y,win] = smoothflow(x)
   % smooth measurement noise
   [y,win] = smoothdata(x,'sgolay');
   y = setnan(y,[],isnan(x));
   y(y<0)=0;
end