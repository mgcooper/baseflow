function [y, win] = smoothnoise(x, varargin)
   %SMOOTHNOISE smooth measurement noise
   %
   %  y = smoothnoise(x) and y = smoothnoise(x, method) smooth x with a
   %  Savitzky-Golay filter (smoothdata 'sgolay') and return the smoothed
   %  data y.
   %
   %  [y, win] = smoothnoise(x, 'annual') smooths each 365-day year
   %  separately. x is a vector of whole years, a matrix with one year per
   %  row, or a matrix with one year per column. y has the size of x. It
   %  also returns the window size win, one value per year. Only the
   %  'annual' method assigns win. Nan elements of x stay nan in y, and the
   %  function sets negative values of y to zero when x is non-negative.

   % check if negative values exist
   noneg = false;
   if all(tocolumn(x(~isnan(x))) >= 0)
      %warning('assuming output y must be >=0')
      noneg = true;
   end

   if nargin > 1 && strcmp(varargin{1},'annual')

      % x is a vector of whole years or a 2-d matrix with one 365-day
      % dimension; organize it so each row is one year
      %validateattributes(x,{'numeric'},{'2d'},mfilename,'x',1)
      sz = size(x);
      if sz(2) == 365
         % data is already organized annually, each row is one year
         numyears = sz(1);
      elseif isvector(x) && mod(numel(x), 365) == 0
         % reshape the input list so each row is one year of data
         numyears = numel(x) / 365;
         x = transpose(reshape(x, 365, numyears));
      elseif sz(1) == 365
         % each column is one year, so transpose so each row is one year
         numyears = sz(2);
         x = transpose(x);
      else
         % try removing feb 29?
         error('the data size is not an even divisor of 365')
      end

      % smooth each year along dim 2, the 365 days of that row
      y = nan(size(x));
      win = nan(numyears, 1);
      for n = 1:numyears
         [y(n,:), win(n)] = smoothdata(x(n,:), 2, 'sgolay');
      end
      y = setnan(y, [], isnan(x));
      if noneg; y(y < 0) = 0; end % or nan?

      % send back the same size it came in
      if sz(2) ~= 365
         y = reshape(transpose(y), sz);
      end
   else
      y = smoothdata(x, 'sgolay');
      y = setnan(y, [], isnan(x));
      if noneg; y(y < 0) = 0; end % or nan?
   end
end