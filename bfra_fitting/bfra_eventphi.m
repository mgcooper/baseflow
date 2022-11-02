function [phi,a] = bfra_eventphi(K,Fits,A,D,L,blate,varargin)
%BFRA_EVENTPHI estimates drainable porosity phi from individual recession
%events using the method of Troch, Troch, and Brutsaert, 1993.
% 
% Required inputs:
%  K     =  table of fitted values of a, b, tau, for each event (output of BFRA_dqdt) 
%  Fits  =  structure containing the fitted q/dqdt timeseries (output of BFRA_dqdt)
%  A     =  basin area contributing to baseflow (L^2)
%  D     =  saturated aquifer thickness (L)
%  L     =  active stream length (L)
%  blate =  late-time b parameter in -dqdt = aq^b (dimensionless)
% 
% Optional name-value inputs:
%  theta    =  effective slope of basin contributing area
%  isflat   =  logical flag indicating if horizontal or sloped aquifer
%              solution is applicable
%  soln1    =  optional early-time theoretical solution
%  soln2    =  optional late-time theoretical solution
% 
% See also cloudphi, fitphi, fitdistphi

%-------------------------------------------------------------------------------
p = MipInputParser;
p.StructExpand = false;
p.FunctionName = 'bfra_eventphi';
p.addRequired('K',@(x)istable(x));
p.addRequired('Fits',@(x)isstruct(x));
p.addRequired('A',@(x)isnumeric(x));
p.addRequired('D',@(x)isnumeric(x));
p.addRequired('L',@(x)isnumeric(x));
p.addRequired('blate',@(x)isnumeric(x));
p.addParameter('method',@(x)ischar(x));
p.addParameter('refqtls',[0.50 0.50],@(x)isnumeric(x));
p.addParameter('theta',0,@(x)isnumeric(x));
p.addParameter('isflat',true,@(x)islogical(x));
p.addParameter('soln1','',@(x)ischar(x));
p.addParameter('soln2','',@(x)ischar(x));
p.parseMagically('caller');
%-------------------------------------------------------------------------------

warning off

% take out the data and init the output
b1          = 3;
b2          = p.Results.blate; 
q           = Fits.q;
dqdt        = Fits.dqdt;
tags        = Fits.eventTag;
eventlist   = rmnan(unique(tags));
numevents   = numel(eventlist);
phi         = nan(numevents,1);
a           = nan(numevents,1);

for n = 1:numevents
   
   event    = K.eventTag(n);
   ifit     = Fits.eventTag == event;
   thisq    = q(ifit);
   thisdqdt = dqdt(ifit);

   if isempty(thisq) || isempty(thisdqdt)
      continue;
   end
      
   % put a line of slope 3 and 1/1.5/bhat through the point cloud
   a1 = bfra_pointcloudintercept(thisq,thisdqdt,b1,'envelope','refqtls',[0.95 0.95]);
   a2 = bfra_pointcloudintercept(thisq,thisdqdt,b2,'envelope','refqtls',refqtls);

   % choose appropriate solutions
   if isempty(soln1) && isempty(soln2)

      if blate==1
         phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','PK62','soln2','BS03');
      elseif blate==3/2
         phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','PK62','soln2','BS04');
      elseif blate>1 && blate<2
         phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','RS05','soln2','RS05');
      else
         % phi remains nan
      end

   % user-specified solutions
   else
      phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,             ...
                                       'soln1',soln1,'soln2',soln2);
   end

   a(n) = a2;
end

warning on
