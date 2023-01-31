function [phi,a] = eventphi(K,Fits,A,D,L,blate,varargin)
%EVENTPHI estimate drainable porosity phi from individual recession events
% 
% Syntax
% 
%     [phi,a] = eventphi(K,Fits,A,D,L,blate,varargin)
% 
% Description
% 
%     Uses the method of Troch, Troch, and Brutsaert, 1993 to compute drainable
%     porosity from early-time and late-time recession parameters and aquifer
%     properties area A, depth D, and channel lenght L.
% 
% Required inputs
% 
%     K        table of a, b, tau, values for each event (output of fitevents) 
%     Fits     structure containing the fitted q/dqdt timeseries (output of bfra.dqdt)
%     A        basin area contributing to baseflow (L^2)
%     D        saturated aquifer thickness (L)
%     L        active stream length (L)
%     blate    late-time b parameter in -dqdt = aq^b (dimensionless)
% 
% Optional name-value inputs
% 
%     theta    effective slope of basin contributing area
%     isflat   logical flag indicating horizontal or sloped aquifer solution
%     soln1    optional early-time theoretical solution
%     soln2    optional late-time theoretical solution
% 
% See also cloudphi, fitphi, fitdistphi
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

%-------------------------------------------------------------------------------
p              = inputParser;
p.StructExpand = false;
p.FunctionName = 'eventphi';

addRequired(   p,'K',                        @(x)isstruct(x));
addRequired(   p,'Fits',                     @(x)isstruct(x));
addRequired(   p,'A',                        @(x)isnumeric(x));
addRequired(   p,'D',                        @(x)isnumeric(x));
addRequired(   p,'L',                        @(x)isnumeric(x));
addRequired(   p,'blate',                    @(x)isnumeric(x));
addParameter(  p,'method',    'envelope',    @(x)ischar(x));
addParameter(  p,'earlyqtls', [0.95 0.95],   @(x)isnumeric(x));
addParameter(  p,'lateqtls',  [0.5 0.5],     @(x)isnumeric(x));
addParameter(  p,'theta',     0,             @(x)isnumeric(x));
addParameter(  p,'isflat',    true,          @(x)islogical(x));
addParameter(  p,'soln1',     '',            @(x)ischar(x));
addParameter(  p,'soln2',     '',            @(x)ischar(x));

parse(p,K,Fits,A,D,L,blate,varargin{:});

method      = p.Results.method;
earlyqtls   = p.Results.earlyqtls;
lateqtls    = p.Results.lateqtls;
theta       = p.Results.theta;
isflat      = p.Results.isflat;
soln1       = p.Results.soln1;
soln2       = p.Results.soln2;
%-------------------------------------------------------------------------------

warning off

% take out the data and init the output
b1          = 3;
b2          = p.Results.blate; 
q           = Fits.q;
dqdt        = Fits.dqdt;
fittags     = Fits.eventTag;
numevents   = numel(K.eventTag);
phi         = nan(numevents,1);
a           = nan(numevents,1);

for n = 1:numevents
   
   ifit     = fittags == K.eventTag(n);
   thisq    = q(ifit);
   thisdqdt = dqdt(ifit);

   if isempty(thisq) || isempty(thisdqdt)
      continue;
   end
      
   % put a line of slope 3 and 1/1.5/bhat through the point cloud
   a1 = bfra.pointcloudintercept(thisq,thisdqdt,b1,'envelope','refqtls',earlyqtls);
   a2 = bfra.pointcloudintercept(thisq,thisdqdt,b2,'envelope','refqtls',lateqtls);

   % choose appropriate solutions
   if isempty(soln1) && isempty(soln2)

      if blate==1
         phi(n) = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','PK62','soln2','BS03');
      elseif blate==3/2
         phi(n) = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','PK62','soln2','BS04');
      elseif blate>1 && blate<2
         phi(n) = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                       'soln1','RS05','soln2','RS05');
      else
         % phi remains nan
      end

   % user-specified solutions
   else
      phi(n) = bfra.fitphi(a1,a2,b2,A,D,L,'isflat',true,             ...
                                       'soln1',soln1,'soln2',soln2);
   end

   a(n) = a2;
end

warning on
