clean

% this script runs the entire analysis for the Kuparuk using the COOP ppt, the
% LTER ppt, and using both COOP and LTER ppt

% set the main options
%----------------------
savedata    = true;
getfits     = false;
fitdata     = true;
plotfigs    = true;
sitename    = bfra_basinname('KUPARUK R NR DEADHORSE AK');
casenames   = {'coop','lter','both'};   % 'coop', 'lter', or 'both'
t1          = datetime(1983,1,1);
t2          = datetime(2020,12,31);
   
% load the daily streamflow and meta data
%-----------------------------------------
load('dailyflow.mat','T','Q');
load('annualflow.mat','Data');
Meta = bfra_loadmeta(sitename,'archive');

% load the active layer thickness data
%--------------------------------------
Calm = bfra_loadcalm(sitename,'archive');
Calm = retime(Calm,'yearly','next'); Calm.Dc(end) =  42.571;

% sychronize the CALM data with the annual flow data
Data  = synchronize(Data,Calm,Data.Time,'fillwithmissing');
years = Data.Time;
Qcmd  = Data.Qcmd;
      
% set parameters to estimate phi
%--------------------------------
Meta.A = Meta.area_m2;
Meta.D = 0.5;
Meta.L = 320000;
Meta.isflat = true;

% run the analysis
%------------------
for n = 1:numel(casenames)

   fname = ['data/ppt/Events_' casenames{n} '.mat'];
   
   % either run the algorithm or just load the data
   if getfits == true

      % load the rain data
      %--------------------
      load(['data/ppt/ppt_' casenames{n} '.mat'],'R');
      
      % get events
      %------------
      opts.Events = bfra_defaultopts('events');
      [Events]    = BFRA_Events(T,Q,R,opts.Events); 

      % fit events
      %------------
      opts.Fits   = bfra_defaultopts('fits');
      opts.Fits   = setfield(opts.Fits,'drainagearea',Meta.A);
      [K,Fits]    = BFRA_dqdt(Events,opts.Fits);
      
      if savedata == true
         save(fname,'Events','Fits','K','opts');
      end
      
   else
      % load the data
      %---------------
      load(fname,'Events','Fits','K','opts');
   end
   
   % ----------------------------------------------------
   %  option to run the analysis on the events
   % ----------------------------------------------------
   
   if fitdata == true
      
      GlobalFit = bfra_globalfit(K,Events,Fits,Meta,'boot',true, ...
                                 'nreps',2000,'plotfits',plotfigs);
   
      if savedata == true
         save(fname,'Events','Fits','K','GlobalFit','opts');
      end
      
   else
      % load the saved analysis and take out the data needed to plot
      load(fname,'Events','Fits','K','GlobalFit','opts');
   end
   
  
   % plot the alt trend
   %--------------------
   if plotfigs == true
      
      % baseflow and saturated layer thickness trends
      %-----------------------------------------------
      bhat  = GlobalFit.b;
      tau   = GlobalFit.tau;
      phi   = GlobalFit.phi;
      pQhat = GlobalFit.pQhat;
      
      Qb       = bfra_baseflow(years,Qcmd,'pctl',pQhat,'show',plotfigs); % cm/d
      [Db,Sb]  = bfra_aquiferthickness(bhat,tau,phi,Qb,true); % cm/yr
      Qb       = Qb.*365.25;  % convert from cm/d to cm/yr
      
      % make separate tables for the Grace period and Calm period
      PlotData = addvars(Data,Qb,Sb,Db);
      inanC    = isnan(PlotData.Dc);%  | isnan(Data.Q);
      DataC    = PlotData(~inanC,:);
      DataG    = PlotData(20:end,:);
      
      % compute trends in aquifer thickness
      f(2*n-1) = figure('Position',[6 241 512 384]);
      trendplot(DataC.Time,DataC.Dc,'units','cm/yr','use',gca,'leg','CALM');
      trendplot(DataC.Time,DataC.Db,'units','cm/yr','use',gca,'leg','BFRA');
      ylabel('active layer anomaly (cm/yr)');

      f(2*n) = figure('Position',[600 241 512 384]); 
      trendplot(DataG.Time,DataG.Dc,'units','cm/yr','use',gca,'leg','CALM');
      trendplot(DataG.Time,DataG.Db,'units','cm/yr','use',gca,'leg','BFRA');
      ylabel('active layer anomaly (cm/yr)');
   end

end

% variable reported replicated
%  phi      0.046    0.046
%  tauhat   25       24.389
%  bhat     1.32     1.3211
%  N        0.36     0.3578
%  pQexp    26       26.523
% 
% I can replicate the paper if I use tauhat = 26.45 or higher
% 
% 


%       % fit tau, a, b
%       %---------------
%       [tau,q,dqdt] = bfra_eventtau(K,Events,Fits,'usefits',false);
%       TauFit = bfra_plfitb(tau,'plotfit',true,'bootfit',true,'nreps',2000);
% 
%       % add q/dqdt to TauFit
%       TauFit.q = q;
%       TauFit.dqdt = dqdt;
% 
%       % fit phi
%       %---------
%       phid(:,1)   = bfra_eventphi(K,Fits,A,D,L,'blate',1);
%       phid(:,2)   = bfra_eventphi(K,Fits,A,D,L,'blate',3/2);
%       phid        = vertcat(phid(:,1),phid(:,2));
%       phi         = bfra_fitdistphi(phid,'cdf','mu');
% 
%       % phid  = bfra_eventphi(K,Fits,A,D,L,'blate',TauFit.b);
%       % phi   = bfra_fitdistphi(phidist(:,3),'cdf');
% 
%       % fit a
%       %-------
%       bhat     = TauFit.b;
%       bhatL    = TauFit.b_L;
%       bhatH    = TauFit.b_H;
%       tau0     = TauFit.tau0;
%       tauhat   = TauFit.tau;
%       itau     = TauFit.taumask;
% 
%       [ahat,ahatLH,xbar,ybar] = bfra_pointcloudintercept(               ...
%                                  q,dqdt,bhat,'taumask',itau,            ...
%                                  'method','median','bci',[bhatL bhatH]  ...
%                                  );
% 
%       % fit Q0 and Qhat
%       %-----------------
%       Q0    = (ahat*tau0)^(1/(1-bhat));   % m3/d
%       Qhat  = Q0*(bhat-2)/(bhat-3);
%       fdc   = fdcurve(Q(Q>0),'refpoints',[Q0 Qhat],'units','m$^3$ s$^{-1}$');
%       pQ0   = fdc.fref(1);
%       pQhat = fdc.fref(2);
% 
%       % baseflow and saturated layer thickness trends
%       %-----------------------------------------------
%       Qb    = bfra_baseflow(Data.Time,Data.Qcmd,'pctl',pQhat,'show',true); % cm/d
%       Db    = bfra_alttrend(tauhat,phi,N,Qb,[]); % cm posted annually
%       Sb    = Db.*phi;     % convert layer thickness to storage
%       Qb    = Qb.*365.25;  % convert from cm/d to cm/yr
%       
%       % add the data to the table
%       PlotData = addvars(Data,Qb,Sb,Db);
%       PlotData = synchronize(PlotData,Calm,Data.Time,'fillwithmissing');
%       
%       % package up the data and save it
%       TauFit.phi = phi;
%       TauFit.a = ahat;
%       TauFit.a_L = ahatLH(1);
%       TauFit.a_H = ahatLH(2);
%       TauFit.xbar = xbar;
%       TauFit.ybar = ybar;
%       TauFit.Q0 = Q0;
%       TauFit.Qhat = Qhat;
%       TauFit.pQhat = pQhat;
%    

   % plot the point cloud
   %-----------------------
%    
%    if plotfigs == true
%    
%       refpts   =  [ybar quantile(-dqdt,0.95)]; % late, early
% 
%       % the og version. blate=bhat, bestfit in legend (no b=1)
%       h        =  bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
%                   'reflines',{'early','late','bestfit'},'reflabels',true, ...
%                   'refpoints',refpts,'addlegend',true);
%                   h.legend.AutoUpdate = 'off';
%                   scatter(xbar,ybar,60,'k','filled','s');
% 
%       % new version. blate=1, bhat in legend (no bestfit)
%       h        =  bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,    ...
%                   'reflines',{'early','late','userfit'},'reflabels',true, ...
%                   'refpoints',refpts,'userab',[ahat bhat],'addlegend',true);
%                   h.legend.AutoUpdate = 'off';
%                   scatter(xbar,ybar,60,'k','filled','s');
%    end
%    
%    if savedata == true
%       fname = ['data/ppt/Events_' casenames{n} '.mat'];
%       save(fname,'Events','Fits','K','TauFit','PhiFit','opts');
%    end
%    
%    clear phidist
