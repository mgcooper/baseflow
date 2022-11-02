function [phi,a] = bfra_cloudphi(q,dqdt,blate,A,D,L,method,varargin)
%BFRA_CLOUDPHI estimates drainable porosity phi from the point cloud using the
%method of Troch, Troch, and Brutsaert, 1993.
% 
% Required inputs:
%  q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%  dqdt        =  discharge rate of change (L T^-2)
%  blate       =  late-time b parameter in -dqdt = aq^b (dimensionless)
%  A           =  basin area contributing to baseflow (L^2)
%  D           =  saturated aquifer thickness (L)
%  L           =  active stream length (L)
%  method      =  method for fitting straight line to point cloud. options are
%                 'median','mean','envelope'.
% 
% Optional name-value inputs:
%  refqtls     =  reference quantiles that together define a pivot point
%                 through which the straight line must pass. use with method
%                 'envelope'.
%  mask        =  logical mask to exclude data
%  theta       =  effective slope of basin contributing area
%  isflat      =  logical flag indicating if horizontal or sloped aquifer
%                 solution is applicable
%  soln1       =  optional early-time theoretical solution
%  soln2       =  optional late-time theoretical solution
%  dispfit     =  logical flag indicating whether to plot the result
% 
%  See also eventphi, fitphi, fitdistphi

%-------------------------------------------------------------------------------
p = inputParser;
p.StructExpand = false;
p.PartialMatching = true;
p.FunctionName = 'bfra_cloudphi';
addRequired(p,'q',@(x)isnumeric(x));
addRequired(p,'dqdt',@(x)isnumeric(x));
addRequired(p,'blate',@(x)isnumeric(x));
addRequired(p,'A',@(x)isnumeric(x));
addRequired(p,'D',@(x)isnumeric(x));
addRequired(p,'L',@(x)isnumeric(x));
addRequired(p,'method',@(x)ischar(x));
addParameter(p,'refqtls',[0.5 0.5],@(x)isnumeric(x));
addParameter(p,'mask',nan,@(x)islogical(x));
addParameter(p,'theta',0,@(x)isnumeric(x));
addParameter(p,'isflat',true,@(x)islogical(x));
addParameter(p,'soln1','RS05',@(x)ischar(x));
addParameter(p,'soln2','RS05',@(x)ischar(x));
addParameter(p,'dispfit',false,@(x)islogical(x));

parse(p,q,dqdt,blate,A,D,L,method,varargin{:});

refqtls  = p.Results.refqtls;
mask     = p.Results.mask;
theta    = p.Results.theta;
isflat   = p.Results.isflat;
soln1    = p.Results.soln1;
soln2    = p.Results.soln2;
dispfit  = p.Results.dispfit;

%-------------------------------------------------------------------------------

% note: the method used for ahat = pointcloudintercept should also be used here

% the easiest way to get a1/a2 is pointcloudintercept. bfra_fitab could also be
% used but this function is intended to fit phi once b is known (or prescribed)

% a1 = early-time a
% b1 = 3 (not involved)
% a2 = late-time a
% b2 = late-time b (bhat or theoretical solution b=1 or b=3/2)

b2 = blate; 
a1 = bfra_pointcloudintercept(q,dqdt,3,'envelope','refqtls',[0.95 0.95]);
a2 = bfra_pointcloudintercept(q,dqdt,b2,method,'refqtls',refqtls,'mask',mask);

switch b2
   case 1
      phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
               'soln2','BS03','dispfit',dispfit);
   case 3/2
      phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
               'soln2','BS04','dispfit',dispfit);
   otherwise
      phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','RS05',  ...
               'soln2','RS05','dispfit',dispfit);
end
a = a2;

% make a dummy handle for the legend and print the value of phi
bfra_pointcloud(q,dqdt,'blate',blate,'mask',mask,'reflines', ...
            {'early','userfit'},'userab',[a2 blate],'reflabels',true);
hdum  = plot(0,0,'Color','none','HandleVisibility','off');
txt   = sprintf('$\\phi_{b=%.2f}=%.3f$',b2,phi);
legend(hdum,txt,'Interpreter','latex','Location','nw','box','off');
