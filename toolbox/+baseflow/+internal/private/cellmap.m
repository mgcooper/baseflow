function varargout = cellmap(fn, varargin)
   %CELLMAP Apply function to cell-array.
   %
   % This function is equivalent to:
   % cellmap = @(fn, varargin) cellfun(fn, varargin{:}, 'UniformOutput', false);
   %
   % See also: arraymap

   varargout = cell(1, nargout);
   [varargout{:}] = cellfun(fn, varargin{:}, 'UniformOutput', false);
end
