function out = printnum(in, precision, varargin)
   %PRINTNUM Display floating point number with specified precision.
   %
   % Syntax
   %
   % out = printnum(in, precision) prints number IN to the screen with PRECISION
   %
   % out = printnum(in, precision, newline) prints number IN to the screen with
   % PRECISION and appends a newline character (useful for programmatic use)
   %
   % Example
   %
   % printnum(pi, 2)
   % ans =
   %     '3.14'
   %
   % printnum(pi, 7)
   % ans =
   %     '3.1415927'
   %
   % printnum(pi, 7, newline)
   %
   % @(C) Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
   %
   % See also: printf
   out = sprintf(['%.' int2str(precision) 'f' varargin{:}],in);
end
