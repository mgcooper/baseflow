function [y,win] = smoothnoise(x,varargin)
%SMOOTHNOISE smooth measurement noise

% check if negative values exist
noneg = false;
if all(tocolumn(x(~isnan(x)))>=0)
   %warning('assuming output y must be >=0')
   noneg = true;
end

if strcmp(varargin{1},'annual')
   
   % with generic reshaping I think it works for arbitrary dimensions
   %validateattributes(x,{'numeric'},{'2d'},mfilename,'x',1)
   sz = size(x);
   if any(sz==365)
      % data is already organized annually, just need the dimension
      dim = find(sz(sz==365));
      numyears = numel(x)./365;
   else
      % try to reshape the data so each row is one year of data
      numyears = size(x)./365;
      if none(mod(numyears,1)==0)
         % try removing feb 29?
         error('the data size is not an even divisor of 365')
      else
         numyears = numyears(mod(numyears,1)==0);
      end
      % reshape the input lists to matrices
      x = reshape(x,numyears,[]);
      sz = size(x);
      dim = find(sz==365); % dim = 2; should be 2 but for 3+ dimensions not sure
   end
   y = nan(size(x));
   win = nan(numyears,1);
   for n = 1:numyears
      [y(n,:),win(n)] = smoothdata(x(n,:),dim,'sgolay');
   end
   y = setnan(y,[],isnan(x));
   if noneg; y(y<0) = 0; end % or nan?
   
   % send back the same size it came in
   y = reshape(y,[],1);
else
   y = smoothdata(x,'sgolay');
   y = setnan(y,[],isnan(x));
   if noneg; y(y<0) = 0; end % or nan?
end