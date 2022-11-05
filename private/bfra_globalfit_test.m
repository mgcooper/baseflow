function GlobalFit = bfra_globalfit_test(K,Events,Fits,Meta,varargin)

% this is just here to demonstrate how to pass an optional string argument
% followed by name-value. the key thing i was missing was the validatestring
% function

%BFRA_GLOBALFIT takes the event-scale recession analysis parameters saved in
%data table K and the event-scale data saved in Events and Fits and computes
%'global' parameters tau, tau0, phi, bhat, ahat, Qexp, and Q0
% 
% Syntax:
% 
%  FIT = BFRA_GLOBALFIT(K,Events,Fits,Meta);
%  FIT = BFRA_GLOBALFIT(K,Events,Fits,Meta,'plotfits',plotfits);
%  FIT = BFRA_GLOBALFIT(K,Events,Fits,Meta,'bootfit',bootfit);
%  FIT = BFRA_GLOBALFIT(K,Events,Fits,Meta,'bootfit',bootfit,'nreps',nreps);
%  FIT = BFRA_GLOBALFIT(___,)
% 
% Author: Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

% Inputs:
%  K, Events, Fits - output of bfra_getevents and bfra_dqdt
%  Meta - struct containing fields area, D0, and L (see below)
%  AnnualFlow - timetable or table of annual flow containing field Qcmd which
%  is the average daily flow (units cm/day) posted annually. 
%  TODO: make the inputs more general, rather than these hard-coded structures
%  and tables

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'bfra_globalfit_test';
p.PartialMatching = true;

validfitopts = {'none','bootfit'};
@(x) any(validatestring(x,validFinishes));

addRequired(p,    'K',                 @(x)istable(x));
addRequired(p,    'Events',            @(x)isstruct(x));
addRequired(p,    'Fits',              @(x)isstruct(x));
addRequired(p,    'Meta',              @(x)isstruct(x)|istable(x) );
addOptional(p,    'fitopts',  'none',  @(x)any(validatestring(x,validfitopts)));
addParameter(p,   'nreps',    1000,    @(x)isnumeric(x));
addParameter(p,   'plotfit',  false,   @(x)islogical(x));

parse(p,K,Events,Fits,Meta,varargin{:});

fitopts = p.Results.fitopts;
plotfit = p.Results.plotfit;
nreps = p.Results.nreps;
%------------------------------------------------------------------------------

% take values out of the data structures that are needed
Q  = Events.Q;       % daily streamflow [m3 d-1]
A  = Meta.A;         % basin area [m2]
D  = Meta.D;         % reference active layer thickness [m]
L  = Meta.L;         % effective stream network length [m]
tf = Meta.isflat;    % use the horizontal or sloped aquifer solution 

% fit tau, a, b
%---------------
[tau,q,dqdt]   = bfra_eventtau(K,Events,Fits,'usefits',false);

if fitopts == "bootfit"
   TauFit = bfra_plfitb(tau,'plot',plotfit,'boot',true,'nreps',nreps);
else
   TauFit = bfra_plfitb(tau,'plot',plotfit);
end

% tau [days]
% q [m3 d-1]
% dqdt [m3 d-2]

% fit phi
%---------
phid(:,1)   = bfra_eventphi(K,Fits,A,D,L,1);
phid(:,2)   = bfra_eventphi(K,Fits,A,D,L,3/2);
phid        = vertcat(phid(:,1),phid(:,2));

if plotfit == true
   phi = bfra_fitdistphi(phid,'mu','cdf');
else
   phi = bfra_fitdistphi(phid,'mu');
end

% phid   = bfra_eventphi(K,Fits,A,D,L,TauFit.b);
% phi    = bfra_fitdistphi(phid,'mu','cdf'); 
% % % % % % % % % % % % % % % % % % % % % % % % % % 

% parameters needed for next steps
%---------------------------------
bhat     = TauFit.b;
bhatL    = TauFit.b_L;
bhatH    = TauFit.b_H;
tau0     = TauFit.tau0;
itau     = TauFit.taumask;

% fit a
%-------
[ahat,ahatLH,xbar,ybar] = bfra_pointcloudintercept(               ...
                           q,dqdt,bhat,'taumask',itau,            ...
                           'method','median','bci',[bhatL bhatH]  ...
                           );

% fit Q0 and Qhat
%-----------------
Q0    = (ahat*tau0)^(1/(1-bhat));   % m3/d
Qhat  = Q0*(bhat-2)/(bhat-3);       % m3/d
u     = 'm$^3$ d$^{-1}$';
fdc   = fdcurve(Q(Q>0),'refpoints',[Q0 Qhat],'units',u,'plotcurve',plotfit);
pQ0   = fdc.fref(1);
pQhat = fdc.fref(2);

% note on units: ahat is estimated from the point cloud. the dimensions of ahat
% are T^b-2 L^1-b. The time is in days and length is m3, so ahat has units
% d^b-2 m^3(1-b) (it's easier if you pretend flow is m d-1). For Q0, we get:
% (d^b-2 m^3(1-b) * d)^(1/1-b) = d^(b-1)/(1-b) m^3(1-b)/(1-b) = m^3 d-1


% plot the pointcloud if requested
%----------------------------------
if plotfit == true
   
   refpts = [ybar quantile(-dqdt,0.95)];

   h = bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,    ...
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
GlobalFit.a    = ahat;
GlobalFit.a_L  = ahatLH(1);
GlobalFit.a_H  = ahatLH(2);
GlobalFit.xbar = xbar;
GlobalFit.ybar = ybar;
GlobalFit.Q0   = Q0;
GlobalFit.Qhat = Qhat;
GlobalFit.pQhat = pQhat;
GlobalFit.pQ0  = pQ0;



