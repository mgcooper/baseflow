function [phi,a] = bfra_cloudphi(q,dqdt,A,D,L,varargin)

%-------------------------------------------------------------------------------
p = MipInputParser;
p.StructExpand = false;
p.FunctionName = 'bfra_cloudphi';
p.addRequired('q',@(x)isnumeric(x));
p.addRequired('dqdt',@(x)isnumeric(x));
p.addRequired('A',@(x)isnumeric(x));
p.addRequired('D',@(x)isnumeric(x));
p.addRequired('L',@(x)isnumeric(x));
p.addParameter('blate',1,@(x)isnumeric(x));
p.addParameter('refpoints',nan,@(x)isnumeric(x));
p.addParameter('mask',nan,@(x)islogical(x));
p.addParameter('theta',0,@(x)isnumeric(x));
p.addParameter('isflat',true,@(x)islogical(x));
p.addParameter('dispfit',false,@(x)islogical(x));
p.parseMagically('caller');
%-------------------------------------------------------------------------------

% constrain the late-time line to pass through the centroid of {tau>tau0}
% ab    = bfra_fitab(q,dqdt,'method','mean','mask',mask,'order',blate);
ab    = bfra_fitab(q,dqdt,'method','median','mask',mask,'order',blate);
ab    = [ab.a ab.b];
h     = bfra_pointcloud(q,dqdt,'blate',blate,'userab',ab,'mask',mask,  ...
         'reflines',{'early','userfit'},'reflabels',true);

if ~isnan(mask)
   h.tau = scatter(q(mask),-dqdt(mask)); % add the itau points:
end

a1    = h.ab.early(1);

% older option to put the line through a ref point
if ~isnan(refpoints)
   a2    = h.ab.late(1);
   b2    = h.ab.late(2);
else
   a2    = h.ab.userfit(1);
   b2    = h.ab.userfit(2);
end

switch blate
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
a     = a2;

% make a dummy handle for the legend and print the value of phi
hdum  = plot(0,0,'Color','none','HandleVisibility','off');
txt   = sprintf('$\\phi_{b=%.2f}=%.2f$',b2,phi);
legend(hdum,txt,'Interpreter','latex','Location','nw','box','off');

