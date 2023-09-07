function varargout = pointcloudintercept(q,dqdt,bhat,method,varargin)
   %POINTCLOUDINTERCEPT Estimate parameter 'a' from the point cloud intercept.
   %
   % Required inputs
   %
   %  q        =  vector double of discharge data (L T^-1)
   %  dqdt     =  vector double of discharge rate of change (L T^-2)
   %  bhat     =  late-time b parameter in -dqdt = aq^b (dimensionless)
   %  method   =  char indicating the fitting method
   %
   % Optional name-value inputs
   %
   %  mask     =  logical mask to exclude data
   %  refqtls  =  reference quantiles that together define a pivot point through
   %              which the straight line must pass. use with method 'envelope'.
   %
   %
   % See also: fitab
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % TODO: consider making this a call to fitab. however, fitab does not return
   % xbar/ybar, and I confirmed the results are identical, but it would be
   % preferable to reduce the potential for inconsistent methods e.g. if this is
   % used to estimate ahat but a different method is used when calling fitab for
   % some other purpose such as fitting phi.

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   persistent inoctave
   if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
   end

   % PARSE INPUTS
   [q, dqdt, bhat, method, thresh, mask, qtls, bci, tau, tau0] = parseinputs( ...
      q, dqdt, bhat, method, varargin{:});

   switch method
      case 'mean'
         %ybar = mean(-dqdt(mask),'omitnan');
         %xbar = mean(q(mask),'omitnan');
         ybar = mean(log(-dqdt(mask)),'omitnan');
         xbar = mean(log(q(mask)),'omitnan');
         ahat = exp(ybar - bhat*xbar);
      case 'median'
         xbar = median(q(mask),'omitnan');
         ybar = median(-dqdt(mask),'omitnan');
         ahat = ybar/xbar^bhat;
      case 'envelope'

         if inoctave
            xbar = quantile(q(mask),qtls(1));
            ybar = quantile(-dqdt(mask),qtls(2));
         else
            xbar = quantile(q(mask),qtls(1),'Method','approximate');
            ybar = quantile(-dqdt(mask),qtls(2),'Method','approximate');
         end
         ahat = ybar/xbar^bhat;

      case 'brutsaert'
         % start with median
         xbar = median(q(mask),'omitnan');
         ybar = median(-dqdt(mask),'omitnan');
         ahat = ybar/xbar^bhat; % init a using the median
         N = numel(q(mask));
         P = 1;
         while P>thresh
            ahat = 0.99*ahat;
            P = sum( (ahat.*q(mask).^bhat) > -dqdt(mask) ) / N;
         end
      case 'cooper' % only works if b>1 and tau/tau0 are provided

         % if no tau>tau0 mask is provided, use the 95th pctl for a1
         if all(mask)

            if inoctave
               xbar = quantile(q,0.95);
               ybar = quantile(-dqdt,0.95);
            else
               xbar = quantile(q,0.95,'Method','approximate');
               ybar = quantile(-dqdt,0.95,'Method','approximate');
            end
         else
            % if a mask is provided, use the 50th pctl of tau<tau0
            if inoctave
               xbar = quantile(q(~mask),qtls(1));
               ybar = quantile(-dqdt(~mask),qtls(2));
            else
               xbar = quantile(q(~mask),qtls(1),'Method','approximate');
               ybar = quantile(-dqdt(~mask),qtls(2),'Method','approximate');
            end
         end
         a0 = ybar/xbar^3;
         ahat = (1/tau)*(sqrt(a0*tau0)*(bhat-3)/(bhat-2))^(bhat-1);

         % temporary method to send back a0 for method 'cooper'
         ahat = [ahat a0];

         % here xbar/ybar are identical to 'envelope'. use this to show that ahat
         % returned by this function is identical to the case where a0 is returned
         % by this function usine method 'envelope' and then passed to the a(a0...)
         % function from bfra.getfunction('aofa0')
         % xbar = quantile(q(mask),qtls(1),'Method','approximate');
         % ybar = quantile(-dqdt(mask),qtls(2),'Method','approximate');
   end

   % NOTE: this isn't the best way to get aL/H, but use it for now
   if ~isnan(bci)
      bhatL = bci(1);
      bhatH = bci(2);
      ahatH = ybar/xbar^bhatL;
      ahatL = ybar/xbar^bhatH;
   else
      ahatH = nan;
      ahatL = nan;
   end

   % PARSE OUTPUTS
   switch nargout
      case 1
         varargout{1} = ahat;
      case 2
         varargout{1} = ahat;
         varargout{2} = [ahatL ahatH];
      case 3
         varargout{1} = ahat;
         varargout{2} = xbar;
         varargout{3} = ybar;
      case 4
         varargout{1} = ahat;
         varargout{2} = [ahatL ahatH];
         varargout{3} = xbar;
         varargout{4} = ybar;
   end

   % % one = ahat
   % % two = ahat, [aL aH]
   % % three = ahat, xbar, ybar
   % % four = ahat, [aL aH], xbar, ybar
end

%% INPUT PARSER
function [q, dqdt, bhat, method, thresh, mask, qtls, bci, tau, tau0] = ...
      parseinputs(q, dqdt, bhat, method, varargin)
   parser = inputParser;
   parser.FunctionName = 'bfra.pointcloudintercept';

   parser.addRequired('q', @isnumeric);
   parser.addRequired('dqdt', @isnumeric);
   parser.addRequired('bhat', @isnumeric);
   parser.addRequired('method', @ischar);
   parser.addOptional('threshold',0.05, @isnumeric);
   parser.addParameter('mask', true(size(q)), @islogical);
   parser.addParameter('refqtls', [0.5 0.5], @isnumeric);
   parser.addParameter('bci', nan, @isnumeric);
   parser.addParameter('tau', nan, @isnumeric);
   parser.addParameter('tau0', nan, @isnumeric);

   parser.parse(q, dqdt, bhat, method, varargin{:});

   thresh = parser.Results.threshold;
   mask = parser.Results.mask;
   qtls = parser.Results.refqtls;
   bci = parser.Results.bci;
   tau = parser.Results.tau;
   tau0 = parser.Results.tau0;
end
