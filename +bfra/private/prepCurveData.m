function [varargout] = prepCurveData( varargin )
   %PREPCURVEDATA Prepare data for curve fitting.
   %
   %  Transform data, if necessary, for the fitCurveData function as follows:
   %
   %       * Return data as columns regardless of the input shapes. Error if
   %       the number of elements do not match. Warn if the number of elements
   %       match, but the sizes are different.
   %
   %       * Convert complex to real (remove imaginary parts) and warn.
   %
   %       * Remove NaN/Inf from data and warn.
   %
   %       * Convert nondouble to double and warn.
   %
   %       * If input X is empty then output X will be a vector of indices into
   %       output Y. The fitCurveData function can then use output vector X as
   %       x-data when there is only y-data.
   %
   %
   %  X = PREPCURVEDATA(X) prepare X for fitCurveData
   %
   %  [X,Y] = PREPCURVEDATA(X,Y) prepare X and Y for fitCurveData
   %
   %  [X,Y,W] = PREPCURVEDATA(X,Y,W) prepare X, Y, and weights W for fitCurveData
   %
   %  Data = PREPCURVEDATA('default') return default curve data for linear model
   %
   %  Data = PREPCURVEDATA(modeltype) return default curve data for model type
   %  specified by char/string-scalar `modeltype`. Valid options are
   %  'linear','exponential','power','semilogx','semilogy'. 'semilogy' is the same
   %  as 'exponential'.
   %
   %
   % Example
   %
   %
   % Matt Cooper, 17-Jan-2023, https://github.com/mgcooper
   % Inspired by prepareCurveData, Copyright 2011 The MathWorks, Inc.
   %
   % See also: genCurveData, fitCurveData, plotCurveData

   % parse inputs
   [x, y, w] = parseinputs(mfilename, varargin{:});

   % If x is empty then replace it by an index vector the same size and shape as y
   if isempty(x)
      x = reshape(1:numel(y), size(y));
   end

   % If weights is empty then return a vector of ones the same size and shape as y
   if isempty(w)
      try
         w = ones(size(y));
      catch
         w = ones(size(x));
      end
   end

   % Ensure that all inputs have the same number of elements
   if numel(x) ~= numel(y) || (nargin == 3 && numel(x) ~= numel(w) )
      error(message('libstats:prepCurveData:unequalNumel'));
   end

   x = double(real(x(:)));
   y = double(real(y(:)));
   w = double(real(w(:)));
   notok = isnan(x) | isnan(y) | isinf(x) | isinf(y);
   x(notok) = [];
   y(notok) = [];
   w(notok) = [];

   % Send back the data
   switch nargout
      case 1
         varargout = {x};
      case 2
         varargout = {x,y};
      case 3
         varargout = {x,y,w};
   end
end

%% input parser
function [x, y, w, modeltype] = parseinputs(mfilename, varargin)
   p = inputParser;
   p.FunctionName = mfilename;
   p.KeepUnmatched = true;

   validstrings = {'default','linear','exponential','power','semilogx','semilogy'};
   validoption = @(x)any(validatestring(x,validstrings));

   p.addOptional('x', [], @(x)isnumeric(x));
   p.addOptional('y', [], @(x)isnumeric(x));
   p.addOptional('w', [], @(x)isnumeric(x));
   p.addOptional('modeltype','default', validoption);

   p.parse(varargin{:});
   x = p.Results.x;
   y = p.Results.y;
   w = p.Results.w;
   modeltype = p.Results.modeltype;
end
