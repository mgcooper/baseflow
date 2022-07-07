function [ mininds,minvals ] = findmin( indata,k,varargin )
%FINDMAX Returns the k indici(s) of the min value and the value at those
% indices. optional arguments follow those of 'min' e.g. 'first','last'
%   Detailed explanation goes here

% NOTE: new function 'mink' does the same thing, I think, and is probably
% more robust

if nargin == 1 % assume we want the first and only the first
   k        =  1;
   position =  'first';
else
   position =  varargin{:};
end

mininds  =   find(indata == min(indata),k,position);

if isempty(mininds); mininds = nan; minvals = nan; return; end

minvals  =   indata(mininds(:));
end

