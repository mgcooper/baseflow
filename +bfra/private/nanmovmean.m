function [Y,Nsum] = nanmovmean(X,F,DIM)
%NANMOVMEAN Moving average of a vector, ignoring NaNs.
%
%  [Y,Nsum] = nanmovmean(X,F,DIM) computes the moving average of the array X
%  over a window of width F (where F is an odd integer) along the specified
%  dimension DIM, while ignoring NaN values. It returns the array Y of averaged
%  values and Nsum, an array indicating the number of non-NaN elements included
%  in each average calculation. If F or DIM are not provided, they default to 1
%  and the first non-singleton dimension of X, respectively. The output arrays
%  Y and Nsum have the same size as X.
%
% Inputs
%  X - Input array, must be a 1D or 2D array.
%  F - Width of moving average window, must be a positive integer.
%  DIM - Dimension along which the moving average is computed, must be 1 or 2.
%
% Outputs
%  Y - Array of the same size as X, containing the computed moving averages.
%  Nsum - Array of the same size as X, indicating the number of non-NaN elements
%         used in calculating each average value.
%
% Example
%  [Y,Nsum] = nanmovmean(rand(5,5),3,1);
%
% See also
%  movmean, mean

% parse inputs
if nargin<1
   help('nanmovmean')
   return
end
if nargin<2 || isempty(F)
   F = 1;
end
F = floor(F/2);
if nargin<3 || isempty(DIM)
   DIM = find(size(X)>1,1,'first');
end
if ~ismatrix(X)
   error('Input X must be a 1D or 2D array.');
end
if ~isscalar(F) || F < 1 || F ~= round(F)
   error('Input F must be a positive integer.');
end
if ~isscalar(DIM) || (DIM ~= 1 && DIM ~= 2)
   error('Input DIM must be either 1 or 2.');
end
if DIM == 2
   X = X.'; %
end
[N,M] = size(X);

% main function

% Initialize output
Y = nan(size(X));
Nsum = nan(size(X));
wasnan = isnan(X);

% Compute moving average
for n = 1:N
   for m = 1:M
      idx = max(1,n-F):min(N,n+F);
      window = X(idx,m);
      Y(n,m) = sum(window(~isnan(window))) / sum(~isnan(window));
      Nsum(n,m) = sum(~isnan(window));
   end
end

% Return the correct size
if DIM == 2
   Y = Y.';
   Nsum = Nsum.';
end

% to replicate movmean, need to set one (F-1)/2 points on either side of the
% nan-window nan
Y(wasnan) = nan;

end
