function out = printf( in,precision,varargin )
%PRINTF print a floating point number(s) to the screen with specified precision
% 
% Syntax
% 
% out = printf( in,precision) prints number IN to the screen with PRECISION
% 
% out = printf( in,precision,newline) prints number IN to the screen with
% PRECISION and appends a newline character (useful for programmatic use)
% 
% Example
% 
% printf(pi,2)
% ans =
%     '3.14'
% 
% printf(pi,7)
% ans =
%     '3.1415927'
% 
% printf(pi,7,newline)
% 
% @(C) Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
% 
% See also

out = sprintf(['%.' int2str(precision) 'f' varargin{:}],in);

