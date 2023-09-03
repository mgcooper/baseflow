function [phi,a] = cloudphi(q,dqdt,blate,A,D,L,method,varargin)
%CLOUDPHI estimate drainable porosity phi from the point cloud
% 
% Syntax
% 
%     [phi,a] = cloudphi(q,dqdt,blate,A,D,L,method,varargin)
% 
% Description
% 
%     [phi,a] = cloudphi(q,dqdt,blate,A,D,L,method) computes drainable porosity
%     from discharge q, first derivative dqdt, aquifer properties area A, depth
%     D, and channel length L, and late-time b-value blate for the event-scale
%     recession equation -dq/dt = aQ^b, using the method of Troch, Troch, and
%     Brutsaert, 1993.
% 
% Required inputs
% 
%     q           discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%     dqdt        discharge rate of change (L T^-2)
%     blate       late-time b parameter in -dqdt = aq^b (dimensionless)
%     A           basin area contributing to baseflow (L^2)
%     D           saturated aquifer thickness (L)
%     L           active stream length (L)
%     method      method for fitting straight line to point cloud. Valid
%                 options include 'median','mean','envelope'.
% 
% Optional name-value inputs
% 
%     refqtls     reference quantiles that together define a pivot point
%                 through which the straight line must pass. use with method
%                 'envelope'.
%     mask        logical mask to exclude data
%     theta       effective slope of basin contributing area
%     isflat      logical flag indicating if horizontal or sloped aquifer
%                 solution is applicable
%     soln1       optional early-time theoretical solution
%     soln2       optional late-time theoretical solution
%     dispfit     logical flag indicating whether to plot the result
% 
% See also eventphi, fitphi, fitdistphi
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% parse inputs
[q, dqdt, blate, A, D, L, method, earlyqtls, lateqtls, userab, mask, ...
   theta, isflat, soln1, soln2, dispfit] = parseinputs(q, dqdt, blate, ...
   A, D, L, method, varargin{:});

% note: the method used for ahat = pointcloudintercept should also be used here

% the easiest way to get a1/a2 is pointcloudintercept. bfra.fitab could also be
% used but this function is intended to fit phi once b is known (or prescribed)

% a1 = early-time a
% b1 = 3 (not involved)
% a2 = late-time a
% b2 = late-time b (bhat or theoretical solution b=1 or b=3/2)

if isnan(userab)
   b2 = blate; 
   a1 = bfra.pointcloudintercept(q,dqdt,3,'envelope','refqtls',earlyqtls);
   a2 = bfra.pointcloudintercept(q,dqdt,b2,method,'refqtls',lateqtls,'mask',mask);
else
   
end

switch b2
   case 1
      phi = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
               'soln2','BS03','dispfit',dispfit);
   case 3/2
      phi = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
               'soln2','BS04','dispfit',dispfit);
   otherwise
      phi = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','RS05',  ...
               'soln2','RS05','dispfit',dispfit);
end
a = a2;

% make a dummy handle for the legend and print the value of phi
bfra.pointcloudplot(q,dqdt,'blate',blate,'mask',mask,'reflines', ...
   {'early','userfit'},'userab',[a2 blate],'reflabels',true);
hdum = plot(0,0,'Color','none','HandleVisibility','off');

if isoctave
   txt = sprintf('phi = %.2f',phi);
   legend(hdum,txt,'Interpreter','tex','Location','northwest','box','off');
else
   txt = sprintf('$\\phi_{b=%.2f}=%.3f$',b2,phi);
   legend(hdum,txt,'Interpreter','latex','Location','northwest','box','off');
end

%% input parser

function [q, dqdt, blate, A, D, L, method, earlyqtls, lateqtls, userab, mask, ...
   theta, isflat, soln1, soln2, dispfit] = parseinputs(q, dqdt, blate, ...
   A, D, L, method, varargin)

parser = inputParser;
parser.StructExpand = false;
parser.FunctionName = 'bfra.cloudphi';

addRequired(parser, 'q', @isnumeric);
addRequired(parser, 'dqdt', @isnumeric);
addRequired(parser, 'blate', @isnumeric);
addRequired(parser, 'A', @isnumeric);
addRequired(parser, 'D', @isnumeric);
addRequired(parser, 'L', @isnumeric);
addRequired(parser, 'method', @ischar);
addParameter(parser,'earlyqtls',[0.95 0.95], @isnumeric);
addParameter(parser,'lateqtls', [0.5 0.5], @isnumeric);
addParameter(parser,'userab', nan, @isnumeric);
addParameter(parser,'mask', true(size(q)), @islogical);
addParameter(parser,'theta', 0, @isnumeric);
addParameter(parser,'isflat', true,  @islogical);
addParameter(parser,'soln1', 'RS05', @ischar);
addParameter(parser,'soln2', 'RS05', @ischar);
addParameter(parser,'dispfit', false, @islogical);

parse(parser,q,dqdt,blate,A,D,L,method,varargin{:});

earlyqtls   = parser.Results.earlyqtls;
lateqtls    = parser.Results.lateqtls;
userab      = parser.Results.userab;
mask        = parser.Results.mask;
theta       = parser.Results.theta;
isflat      = parser.Results.isflat;
soln1       = parser.Results.soln1;
soln2       = parser.Results.soln2;
dispfit     = parser.Results.dispfit;

%% 
% found this in an older test version, need to integrate or delete
% 
% if isflat
%    switch blate
%       case 1
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
%             'soln2','BS03','dispfit',dispfit);
%       case 3/2
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','PK62', ...
%             'soln2','BS04','dispfit',dispfit);
%       otherwise
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','RS05',  ...
%             'soln2','RS05','dispfit',dispfit);
%    end
% else
%    switch blate
%       case 1
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','BR94', ...
%             'soln2','BR94','dispfit',dispfit,'theta',theta);
%       case 3/2
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','BR94', ...
%             'soln2','RS06','dispfit',dispfit,'theta',theta);
%       otherwise
%          phi = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',isflat,'soln1','BR94',  ...
%             'soln2','RS06','dispfit',dispfit,'theta',theta);
%    end
% end
% a = a2;