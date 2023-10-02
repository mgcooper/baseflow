function varargout = ccdf(data,varargin)
   %CCDF compute complementary cumulative distribution function
   %
   %  [F, X] = ccdf(data) returns the empirical complementary cumulative
   %  distribution function F evaluated at points X. F is 1 minus the F returned
   %  by MATLAB's built in ecdf function.
   %
   %  Fx = ccdf(data) returns [F X] concatentated in one array.
   %
   %  [_] = ccdf(data, 'makeplot', true) also plots the function.
   %
   % See also ccdf, plcdf

   % parse inputs
   p = inputParser;
   p.addRequired('data',@isnumeric);
   p.addParameter('makeplot',false,@islogical);
   p.parse(data, varargin{:});

   % main
   [f,x] = ecdf(data);
   F = 1-f;

   % option to plot
   if p.makeplot == true
      figure; plot(x,F);
      xlabel('$x$');
      ylabel('$P(X\ge x)$');
   end

   % manage output
   switch nargout
      case 1
         varargout{1} = [F,x];
      case 2
         varargout{1} = F;
         varargout{2} = x;
   end
end