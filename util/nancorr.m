function [Rho,Pval] = nancorr( X,Y,varargin )
%NANCORR compute the sample correlation coefficient for data with NaNs
% 
%  [Rho,Pval] = nancorr( X,Y,varargin )
% 
%  X is the one series, Y is another.
% 
% See also

X=X(:);
Y=Y(:);

if length(X) ~= length(Y)
   error('The samples must be of the same length')
end

nanindsx = find(isnan(X));
nanindsy = find(isnan(Y));
naninds  = unique([nanindsx;nanindsy]);

X(naninds) = [];
Y(naninds) = [];

[Rho,Pval] = corr(X,Y,varargin{:});
