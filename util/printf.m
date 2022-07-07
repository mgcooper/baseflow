function out = printf( in,precision,varargin )
%PRINTF prints a floating point number(s) to the screen with specified
%precision
%   Detailed explanation goes here

p = ['%.' int2str(precision) 'f' varargin{:}];
% p = ['%.' int2str(precision) 'f\n']; % not sure why i had the new line
% command, but I removed it because it was causing trouble

% adding it back worked as desired on my windows, so might have been a
% windows/mac issue. Instead I added the varargin and it works

out = sprintf(p,in);

end

