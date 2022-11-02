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
p = MipInputParser;
p.StructExpand = false;
p.PartialMatching = true;
p.FunctionName = 'bfra_cloudphi';
p.addRequired('q',@(x)isnumeric(x));
p.addRequired('dqdt',@(x)isnumeric(x));
p.addRequired('blate',@(x)isnumeric(x));
p.addRequired('A',@(x)isnumeric(x));
p.addRequired('D',@(x)isnumeric(x));
p.addRequired('L',@(x)isnumeric(x));
p.addRequired('method',@(x)ischar(x));
p.addParameter('refqtls',[0.5 0.5],@(x)isnumeric(x));
p.addParameter('mask',nan,@(x)islogical(x));
p.addParameter('theta',0,@(x)isnumeric(x));
p.addParameter('isflat',true,@(x)islogical(x));
p.addParameter('soln1','RS05',@(x)ischar(x));
p.addParameter('soln2','RS05',@(x)ischar(x));
p.addParameter('dispfit',false,@(x)islogical(x));
p.parseMagically('caller');
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



% constrain the late-time line to pass through the centroid of {tau>tau0}
% ab    = bfra_fitab(q,dqdt,'method','median','mask',mask,'order',blate);
% ab    = [ab.a ab.b];

% a1 = bfra_pointcloudintercept(q,dqdt,3,'envelope','refqtls',[0.95 0.95]);
% a2 = bfra_pointcloudintercept(q,dqdt,b2,method,'refqtls',refqtls,'mask',mask);

% the old method to get a1
% h = bfra_pointcloud(q,dqdt,'blate',blate,'mask',mask,'reflines', ...
%             {'early','userfit'},'userab',[a2 blate],'reflabels',true);
% a1 = h.ab.early(1);

% % older option to put the line through a ref point
% if ~isnan(refpoints)
%    a2    = h.ab.late(1);
%    b2    = h.ab.late(2);
% else
%    a2    = h.ab.userfit(1);
%    b2    = h.ab.userfit(2);
% end
% % % % % % %  


% % % % % % % %  this is the method used in eventphi
% [~,ab1] = bfra_refline(q,-dqdt,'refslope',3,'plot',false,'refline','phifit');
% a1 = ab1(1);
% a2 = bfra_pointcloudintercept(q,dqdt,blate,method,'mask',mask,'refqtls',refqtls);
% b2 = blate;
% 
% % % this calls reflineintercept and puts the late-time line through the 5th prctl
% % [~,ab2] = bfra_refline(q(mask),-dqdt(mask),'refslope',blate,'plot',false,'refline','phifit');
% % a2 = ab2(1);
% % b2 = ab2(2);

% the reason this gives a different answer is because the call to refline
% doesn't use the 'phifit' option and instead it uses the refpoint which uses
% the median of the q value and the refpont for the y value, whereas the phifit
% method calls reflineintercept. note this agrees with pointcloudintercept for
% that same reason (pointcloudintercept uses the xmedian / yrefpoint method

% refpt1 = quantile(-dqdt,0.95);
% refpt2 = quantile(-dqdt(mask),0.05);
% [~,ab1] = bfra_refline(q,-dqdt,'refslope',3,'plot',false,'refpoint',refpt1);
% [~,ab2] = bfra_refline(q(mask),-dqdt(mask),'refslope',blate,'plot',false,'refpoint',refpt2);

% % % % % % %  


