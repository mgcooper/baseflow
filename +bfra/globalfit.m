function GlobalFit = globalfit(K,Events,Fits,varargin)
%GLOBALFIT takes the event-scale recession analysis parameters saved in
%data table K and the event-scale data saved in Events and Fits and computes
%'global' parameters tau, tau0, phi, bhat, ahat, Qexp, and Q0
% 
% Syntax:
% 
%  FIT = bfra.GLOBALFIT(K,Events,Fits);
%  FIT = bfra.GLOBALFIT(K,Events,Fits,opts);
%  FIT = bfra.GLOBALFIT(K,Events,Fits,Meta,'plotfits',plotfits);
%  FIT = bfra.GLOBALFIT(K,Events,Fits,Meta,'bootfit',bootfit);
%  FIT = bfra.GLOBALFIT(K,Events,Fits,Meta,'bootfit',bootfit,'nreps',nreps);
%  FIT = bfra.GLOBALFIT(___,)
% 
% Author: Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

% Required inputs:
%  K, Events, Fits - output of bfra.getevents and bfra.dqdt
%  opts - struct containing fields area, D0, and L (see below)
%  AnnualFlow - timetable or table of annual flow containing field Qcmd which
%  is the average daily flow (units cm/day) posted annually. 
%  TODO: make the inputs more general, rather than these hard-coded structures
%  and tables
%
% See also setopts

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'bfra.globalfit';
p.PartialMatching = true;
p.StructExpand    = true;
addRequired(p,    'K',                             @(x)istable(x)                );
addRequired(p,    'Events',                        @(x)isstruct(x)               );
addRequired(p,    'Fits',                          @(x)isstruct(x)               );
addParameter(p,   'drainagearea',   nan,           @(x)isnumericscalar(x)        );
addParameter(p,   'aquiferdepth',   nan,           @(x)isnumericscalar(x)        );
addParameter(p,   'streamlength',   nan,           @(x)isnumericscalar(x)        );
addParameter(p,   'aquiferslope',   nan,           @(x)isnumericscalar(x)        );
addParameter(p,   'aquiferbreadth', nan,           @(x)isnumericscalar(x)        );
addParameter(p,   'isflat',         true,          @(x)islogicalscalar(x)        );
addParameter(p,   'plotfits',       false,         @(x)islogicalscalar(x)        );
addParameter(p,   'bootfit',        false,         @(x)islogicalscalar(x)        );
addParameter(p,   'nreps',          1000,          @(x)isdoublescalar(x)         );
addParameter(p,   'phimethod',      'pointcloud',  @(x)ischar(x)                 );
addParameter(p,   'refqtls',        [0.50 0.50],   @(x)isnumericvector(x)        );
addParameter(p,   'earlyqtls',      [0.90 0.90],   @(x)isnumericvector(x)        );
addParameter(p,   'lateqtls',       [0.50 0.50],   @(x)isnumericvector(x)        );
      

parse(p,K,Events,Fits,varargin{:});

drainagearea   = p.Results.drainagearea;     % basin area [m2]
aquiferdepth   = p.Results.aquiferdepth;     % reference active layer thickness [m]
streamlength   = p.Results.streamlength;     % effective stream network length [m]
aquiferslope   = p.Results.aquiferslope;
aquiferbreadth = p.Results.aquiferbreadth;
plotfits       = p.Results.plotfits;
bootfit        = p.Results.bootfit;
nreps          = p.Results.nreps;
phimethod      = p.Results.phimethod;
refqtls        = p.Results.refqtls;
earlyqtls      = p.Results.earlyqtls;
lateqtls       = p.Results.lateqtls;

%-------------------------------------------------------------------------------

% take values out of the data structures that are needed
Q  = Events.Q;       % daily streamflow [m3 d-1]

% fit tau, a, b (tau [days], q [m3 d-1], dqdt [m3 d-2])
%---------------
[tau,q,dqdt,tags] = bfra.eventtau(K,Events,Fits,'usefits',false);
TauFit = bfra.plfitb(tau,'plot',plotfits,'boot',bootfit,'nreps',nreps);


% parameters needed for next steps
%---------------------------------
bhat     = TauFit.b;
bhatL    = TauFit.b_L;
bhatH    = TauFit.b_H;
tau0     = TauFit.tau0;
tauhat   = TauFit.tau;
itau     = TauFit.taumask;

% fit a
% -------
[ahat,ahatLH,xbar,ybar] =  bfra.pointcloudintercept(q,dqdt,bhat,'envelope',  ...
                           'refqtls',refqtls,'mask',itau,'bci',[bhatL bhatH]);

% fit Q0 and Qhat
%-----------------
[Qexp,Q0,pQexp,pQ0] = bfra.expectedQ(ahat,bhat,tauhat,q,dqdt,tau0,'qtls',Q,'mask',itau);


% fit phi
%---------
switch phimethod 
   case 'distfit'
      phid = bfra.eventphi(K,Fits,drainagearea,aquiferdepth,streamlength,bhat,...
                           'refqtls',refqtls);
      phi = bfra.fitdistphi(phid,'mu','cdf');
   case 'pointcloud'
      phi = bfra.cloudphi(q,dqdt,bhat,drainagearea,aquiferdepth,streamlength,...
                           'envelope','refqtls',refqtls,'mask',itau);
end


% fit k
%---------
[k,Q0_2,D_2] = bfra.aquiferprops(q,dqdt,ahat,bhat,phi,drainagearea,...
                  aquiferdepth,streamlength,'RS05','mask',itau);


% Q0    = Qexp*(3-b)/(2-b);

% note on units: ahat is estimated from the point cloud. the dimensions of ahat
% are T^b-2 L^1-b. The time is in days and length is m3, so ahat has units
% d^b-2 m^3(1-b) (it's easier if you pretend flow is m d-1). For Q0, we get:
% (d^b-2 m^3(1-b) * d)^(1/1-b) = d^(b-1)/(1-b) m^3(1-b)/(1-b) = m^3 d-1

% plot the pointcloud if requested
%----------------------------------
if plotfits == true
   
   refpts = [ybar quantile(-dqdt,0.95)];

   h = bfra.pointcloudplot(q,dqdt,'blate',1,'mask',itau,    ...
   'reflines',{'early','late','userfit'},'reflabels',true, ...
   'refpoints',refpts,'userab',[ahat bhat],'addlegend',true);
   
   h.legend.AutoUpdate = 'off';
   scatter(xbar,ybar,60,'k','filled','s');
   
end



% package up the data and save it
GlobalFit      = TauFit;
GlobalFit.phi  = phi;
GlobalFit.q    = q;
GlobalFit.dqdt = dqdt;
GlobalFit.tags = tags;
GlobalFit.a    = ahat;
GlobalFit.a_L  = ahatLH(1);
GlobalFit.a_H  = ahatLH(2);
GlobalFit.xbar = xbar;
GlobalFit.ybar = ybar;
GlobalFit.Q0   = Q0;
GlobalFit.Qexp = Qexp;
GlobalFit.pQexp = pQexp;
GlobalFit.pQ0  = pQ0;

