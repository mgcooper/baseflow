
clean

% this script runs the entire analysis for the Kuparuk

getfits     = false;
getflow     = false;

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% 	load the data
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

basinname   = bfra_basinname('KUPARUK R NR DEADHORSE AK');
t1          = datetime(1983,1,1);
t2          = datetime(2020,12,31);
Meta        = bfra_loadmeta(basinname);
Calm        = bfra_loadcalm(basinname);
aream2      = Meta.area_m2;
utext       = 'm$^3$ s$^{-1}$';

% load the streamflow and rainfall data for input to the algorithm
load('dailyflow.mat');
load('annualflow.mat');

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% 	run the recession analysis
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% either run the algorithm or just load the data
if getfits == true
   
   % get events
   optsE       = bfra_defaultopts('events');
   [Events]    = BFRA_Events(T,Q,R,optsE); 

   % fit events
   optsF       = bfra_defaultopts('fits');
   optsF       = setfield(optsF,'drainagearea',aream2);
   [K,Fits]    = BFRA_dqdt(Events,optsF);

   if savedata == true
      save('data/Events.mat','Events','Fits','K','optsE','optsF');
   end
   
else % load the baseflow recession Events and the Fits
   load('data/Events.mat');
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%     estimate tau, a, b
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% fit the distribution then get the expected value of tau
[tau,q,dqdt]   = bfra_eventtau(K,Events,Fits,'usefits',false);
[bhat,tau0]    = bfra_fittau(tau,'plotfit',true,'bootstrap',true);

% compute uncertainties
TauFit   = bfra_gpfitb(tau,'xmin',tau0,'plot',false,'var','\tau',    ...
                        'label',true,'boot',true);

itau     = tau>tau0;
tauhat   = tau0*(2-bhat)/(3-2*bhat);
N        = bfra_conversions(bhat,'b','N','isflat',true);

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%     estimate phi
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
isflat   = true;
D        = 0.5;
A        = 8.4e9;
L        = 320*1000;
B        = A/2/L;
E        = 265;               % elevation
sintheta = E/B;
theta    = asind(sintheta);
eta      = B/D*tand(theta);

% method 1: point cloud b=3 and b=1,1.5, and b=bhat
%~~~~~~~~~~

% phi(1) = bfra_cloudphi(q,dqdt,A,D,L,'blate',1,'mask',itau,'disp',false);
% phi(2) = bfra_cloudphi(q,dqdt,A,D,L,'blate',3/2,'mask',itau,'disp',false);
% phi(3) = bfra_cloudphi(q,dqdt,A,D,L,'blate',bhat,'mask',itau,'disp',false);
% 
% [mean(phi) std(phi)] % mean +/- 1 std = 0.07 pm 0.03

% method 2: fit b=3 and b=1/1.5 through all events
%~~~~~~~~~~
phidist(:,1)   = bfra_eventphi(K,Fits,A,D,L,'blate',1);
phidist(:,2)   = bfra_eventphi(K,Fits,A,D,L,'blate',3/2);
phidist(:,3)   = bfra_eventphi(K,Fits,A,D,L,'blate',bhat);

PhiFit         = bfra_fitdistphi(vertcat(phidist(:,1),phidist(:,2)),'cdf');
phi            = PhiFit.mean; % 0.03;

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%     plot the point cloud, get expected values
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

refpts   = [mean(-dqdt(itau),'omitnan') quantile(-dqdt,0.95)];
h        = bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
            'reflines',{'early','late','bestfit'},'reflabels',true, ...
            'refpoints',refpts,'addlegend',true);
ahat     = h.ab.late(1);         
Q0hat    = (ahat*tau0)^(1/(1-bhat));   % m3/d
Qhat     = Q0hat*(bhat-2)/(bhat-3);
fdc      = fdcurve(Q(Q>0),'refpoints',[Q0hat Qhat],'units',utext);
pQexp    = fdc.fref; 

