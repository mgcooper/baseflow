function varnames = gettablevarnames(T)
%GETTABLEVARNAMES Return table var names as a cell array
% 
%  varnames = gettablevarnames(T)
% 
% See also: gettableunits

varnames = T.Properties.VariableNames;