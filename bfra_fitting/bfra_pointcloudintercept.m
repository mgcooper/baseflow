function varargout = bfra_pointcloudintercept(q,dqdt,bhat,method,varargin)
%bfra_pointcloudintercept estimate parameter 'a' from the point cloud intercept
% 
% Required inputs:
%  q        =  vector double of discharge data (L T^-1)
%  dqdt     =  vector double of discharge rate of change (L T^-2)
%  bhat     =  late-time b parameter in -dqdt = aq^b (dimensionless)
%  method   =  char indicating the fitting method
% 
% Optional inputs:
%  mask     =  logical mask to exclude data
%  refqtls  =  reference quantiles that together define a pivot point through
%              which the straight line must pass. use with method 'envelope'.
% 
% 
% See also: bfra_fitab

% input parsing
%-------------------------------------------------------------------------------
p=inputParser;
p.FunctionName='bfra_pointcloudintercept';
p.PartialMatching = true;
addRequired(p,'q',@(x)isnumeric(x));
addRequired(p,'dqdt',@(x)isnumeric(x));
addRequired(p,'bhat',@(x)isnumeric(x));
addRequired(p,'method',@(x)ischar(x));
addParameter(p,'mask',true(size(q)),@(x)islogical(x));
addParameter(p,'refqtls',[0.5 0.5],@(x)isnumeric(x));
addParameter(p,'bci',nan,@(x)isnumeric(x));
parse(p,q,dqdt,bhat,method,varargin{:});

method = p.Results.method;
mask = p.Results.mask;
qtls = p.Results.refqtls;
bci = p.Results.bci;
%-------------------------------------------------------------------------------

% TODO: consider making this a call to fitab. however, fitab does not return
% xbar/ybar, and I confirmed the results are identical, but it would be
% preferable to reduce the potential for inconsistent methods e.g. if this is
% used to estimate ahat but a different method is used when calling fitab for
% some other purpose such as fitting phi.

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
      xbar = quantile(q(mask),qtls(1),'Method','approximate');
      ybar = quantile(-dqdt(mask),qtls(2),'Method','approximate');
      ahat = ybar/xbar^bhat;
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
      
% one = ahat
% two = ahat, [aL aH]
% three = ahat, xbar, ybar
% four = ahat, [aL aH], xbar, ybar




