function varargout = bfra_pointcloudintercept(q,dqdt,bhat,varargin)
%bfra_pointcloudintercept estimate parameter 'a' from the point cloud intercept

% input parsing
%-------------------------------------------------------------------------------
p=inputParser;
p.FunctionName='bfra_pointcloudintercept';
addRequired(p,'q',@(x)isnumeric(x));
addRequired(p,'dqdt',@(x)isnumeric(x));
addRequired(p,'bhat',@(x)isnumeric(x));
addParameter(p,'taumask',true(size(q)),@(x)islogical(x));
addParameter(p,'method','median',@(x)ischar(x)|isstring(x));
addParameter(p,'qtl',0.25,@(x)isnumeric(x));
addParameter(p,'bci',nan,@(x)isnumeric(x));
parse(p,q,dqdt,bhat,varargin{:});

taumask = p.Results.taumask;
method = p.Results.method;
qtl = p.Results.qtl;
bci = p.Results.bci;
%-------------------------------------------------------------------------------

switch method
   case 'median'
      ybar = median(-dqdt(taumask),'omitnan');
      xbar = median(q(taumask),'omitnan');
   case 'quantile'
      ybar = quantile(-dqdt(taumask),qtl);
      xbar = median(q(taumask),'omitnan');
   case 'mean'
      ybar = mean(-dqdt(taumask),'omitnan');
      xbar = mean(q(taumask),'omitnan');
end

ahat = ybar/xbar^bhat;

% NOTE: this isn't the best way to get aL/H, but use it for now
if ~isnan(bci)
   bhatL = bci(1);
   bhatH = bci(2);
   ahatH = ybar/xbar^bhatL;
   ahatL = ybar/xbar^bhatH;
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




