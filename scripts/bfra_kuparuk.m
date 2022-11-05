clean

% PICK UP HERE - this is a test to replace the existing bfra.kuparuk. Then I
% need to figure out why the lter+coop leads to higher trends than previously,
% most likely it is the method used in bfra.eventphi or refline or
% poutcloudintercept. figure out the right way then make figures for respone
% letter, confert this and other scripts to .md examples and resubmit

% this script runs the entire analysis for the Kuparuk

% NOW I AM GETTING THE RIGHT ANSWER again, 0.31 and 0.77 ... so checkout the
% project branches and see what happens, if it's working, i think we can move
% on from Troch ... key thing is that L is NOT INVOLVED in estimating phi, so
% we don't even have to report it, b/c if someone did the calculation they
% would find that drainage density is about 0.03 so L prob needs to be a factor
% of 10 higher, which would produce bettter ksat estiamtes otherwise other than
% clarifying a method to get Q0 I am not sure troch rpovides anything else

% set the main options
%----------------------
savedata    = false;
fitevents   = false;
fitglobal   = true;
plotfigs    = true;
bootfit     = false;
nreps       = 1;
sitename    = bfra.basinname('KUPARUK R NR DEADHORSE AK');
t1          = datetime(1983,1,1);
t2          = datetime(2020,12,31);
testrain    = 'none';

% this is the filename that will be used to save the output
fname    = 'data/Events.mat';

% load the daily streamflow and meta data
%-----------------------------------------
load('dailyflow.mat','T','Q','R');
load('annualflow.mat','Data');
Meta = bfra.loadmeta(sitename,'archive');


% temporary option to use different rain
%==========================================
if ~strcmp(testrain,'none')
   load(['data/ppt/ppt_' testrain '.mat'],'R')
end
%==========================================

% load the active layer thickness data
%--------------------------------------
Calm = bfra.loadcalm(sitename,'archive');
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
   
% either run the algorithm or just load the data
if fitevents == true

   % set opts
   %----------
   opts.Events = bfra.defaultopts('events');
   opts.Fits   = bfra.defaultopts('fits');
   opts.Fits   = setfield(opts.Fits,'drainagearea',Meta.A);
   
   % get events
   %------------
   [Events]    = bfra.wrapEvents(T,Q,R,opts.Events); 

   % fit events
   %------------
   [K,Fits]    = bfra.wrapEventFits(Events,opts.Fits);

   if savedata == true
      save(fname,'Events','Fits','K','opts');
   end

else
   % load the data
   %---------------
   if ~strcmp(testrain,'none')
      load(['data/ppt/Events_' testrain '.mat'],'Events','Fits','K','opts');
   else
      load(fname,'Events','Fits','K','opts');
   end
end

% ---------------------------------------------------------------------
%  run the global fitting analysis on the events or just load the data
% ---------------------------------------------------------------------

if fitglobal == true

   GlobalFit = bfra.globalfit(K,Events,Fits,Meta,'boot',false, ...
                              'nreps',2000,'plotfit',plotfigs);

   if savedata == true
      save(fname,'Events','Fits','K','GlobalFit','opts');
   end

else
   % load the saved analysis and take out the data needed to plot
   load(fname,'Events','Fits','K','GlobalFit','opts');
end

% -----------------------------------------------
%  compute baseflow and aquifer thickness trends
% -----------------------------------------------

% parameters 
%------------
bhat  = GlobalFit.b;
tau   = GlobalFit.tau;
phi   = GlobalFit.phi;
pQexp = GlobalFit.pQexp;

% compute baseflow and aquifer thickenss
%----------------------------------------
[Qb,~,~,~,hb,ha] = bfra.baseflow(years,Qcmd,'pctl',pQexp,'show',false); % cm/d
[Db,Sb]  = bfra.aquiferthickness(bhat,tau,phi,Qb,true); % cm/yr
Qb       = Qb.*365.25;  % convert from cm/d/yr to cm/yr/yr

f(1) = hb.figure;
f(2) = ha.figure;

% add to the GlobalFit
%----------------------
GlobalFit.Qb = Qb;
GlobalFit.Db = Db;
GlobalFit.Sb = Sb;

if savedata == true
   save(fname,'Events','Fits','K','GlobalFit','opts');
end
   

% option to plot the alt trend
%------------------------------
if plotfigs == true

   % make separate tables for the Grace period and Calm period
   PlotData = addvars(Data,Qb,Sb,Db);
   inanC    = isnan(PlotData.Dc);%  | isnan(Data.Q);
   DataC    = PlotData(~inanC,:);
   DataG    = PlotData(20:end,:);

   % compute trends in aquifer thickness
   f(3) = figure('Position',[6 241 512 384]);
   trendplot(DataC.Time,DataC.Dc,'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataC.Time,DataC.Db,'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

   f(4) = figure('Position',[600 241 512 384]); 
   trendplot(DataG.Time,DataG.Dc,'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataG.Time,DataG.Db,'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

end

GlobalFit.a

autoArrangeFigures(3,2,2)

% tileopenfigs('deletefigs',true);

% figure(1); plot(1:10,1:10,'b');
% figure(2); plot(1:10,1:10,'r');
% figure(3); plot(1:10,1:10,'g');
% figure(4); plot(1:10,1:10,'c');
% 
% tileopenfigs('deletefigs',true);

% s1 = '1';
% s2 = '2';
% s3 = '3';
% s4 = '4';
% layout = {s1 s2; s3 s4};
% fm = sl.plot.fig_merger(layout);
% % fm = sl.plot.fig_merger({'1,1','2,2';'3,3','4,4'});
% 
% 
% figure(1)
% subplot(2,1,1)
% plot(1:10,'r')
% subplot(2,1,2)
% plot(11:20,'g')
% 
% figure(2)
% subplot(2,1,1)
% plot(21:30,'b')
% subplot(2,1,2)
% plot(31:40,'k')
% 
% s1 = '1,2';    %(fig 1, id 1)
% s2 = '2,1,1';  %(fig 2, row 1, cell 1) % OR '2,1'
% s3 = '1,1';
% s4 = '2,2';
% layout = {s1 s2; s3 s4};
% sl.plot.fig_merger(layout)
% % See figure 3
% 
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% %% plot the point cloud
% 
% % see scripts/ for pub-quality figures
% % ab       = bfra.fitab(q,dqdt,'mask',itau,'method','mean','order',1.3);
% % pcloud   = bfra.pointcloudplot(q,dqdt,'mask',itau,'reflabels',true,'reflines', ...
% %             {'early','bestfit' ,'upperenvelope','lowerenvelope','userfit'}, ...
% %             'userab',[ab.a ab.b]);
% % 
% % 
% % % BELOW HERE IS STUFF THAT ISN'T IN THE 'WORKFLOW'
% % 
% % 
% % %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% % %  Figure 5: hyd cond.
% % %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% 
% 
% 
% 
% 
% % variable reported replicated
% %  phi      0.046    0.046
% %  tauhat   25       24.389
% %  bhat     1.32     1.3211
% %  N        0.36     0.3578
% %  pQexp    26       26.523
% % 
% % I can replicate the paper if I use tauhat = 26.45 or higher
% % 
% % 
% 
% 
% %       % fit tau, a, b
% %       %---------------
% %       [tau,q,dqdt] = bfra.eventtau(K,Events,Fits,'usefits',false);
% %       TauFit = bfra.plfitb(tau,'plotfit',true,'bootfit',true,'nreps',2000);
% % 
% %       % add q/dqdt to TauFit
% %       TauFit.q = q;
% %       TauFit.dqdt = dqdt;
% % 
% %       % fit phi
% %       %---------
% %       phid(:,1)   = bfra.eventphi(K,Fits,A,D,L,1);
% %       phid(:,2)   = bfra.eventphi(K,Fits,A,D,L,3/2);
% %       phid        = vertcat(phid(:,1),phid(:,2));
% %       phi         = bfra.fitdistphi(phid,'cdf','mu');
% % 
% %       % phid  = bfra.eventphi(K,Fits,A,D,L,TauFit.b);
% %       % phi   = bfra.fitdistphi(phidist(:,3),'cdf');
% % 
% %       % fit a
% %       %-------
% %       bhat     = TauFit.b;
% %       bhatL    = TauFit.b_L;
% %       bhatH    = TauFit.b_H;
% %       tau0     = TauFit.tau0;
% %       tauhat   = TauFit.tau;
% %       itau     = TauFit.taumask;
% % 
% %       [ahat,ahatLH,xbar,ybar] = bfra.pointcloudintercept(               ...
% %                                  q,dqdt,bhat,'taumask',itau,            ...
% %                                  'method','median','bci',[bhatL bhatH]  ...
% %                                  );
% % 
% %       % fit Q0 and Qhat
% %       %-----------------
% %       Q0    = (ahat*tau0)^(1/(1-bhat));   % m3/d
% %       Qhat  = Q0*(bhat-2)/(bhat-3);
% %       fdc   = fdcurve(Q(Q>0),'refpoints',[Q0 Qhat],'units','m$^3$ s$^{-1}$');
% %       pQ0   = fdc.fref(1);
% %       pQhat = fdc.fref(2);
% % 
% %       % baseflow and saturated layer thickness trends
% %       %-----------------------------------------------
% %       Qb    = bfra.baseflow(Data.Time,Data.Qcmd,'pctl',pQhat,'show',true); % cm/d
% %       Db    = bfra.alttrend(tauhat,phi,N,Qb,[]); % cm posted annually
% %       Sb    = Db.*phi;     % convert layer thickness to storage
% %       Qb    = Qb.*365.25;  % convert from cm/d to cm/yr
% %       
% %       % add the data to the table
% %       PlotData = addvars(Data,Qb,Sb,Db);
% %       PlotData = synchronize(PlotData,Calm,Data.Time,'fillwithmissing');
% %       
% %       % package up the data and save it
% %       TauFit.phi = phi;
% %       TauFit.a = ahat;
% %       TauFit.a_L = ahatLH(1);
% %       TauFit.a_H = ahatLH(2);
% %       TauFit.xbar = xbar;
% %       TauFit.ybar = ybar;
% %       TauFit.Q0 = Q0;
% %       TauFit.Qhat = Qhat;
% %       TauFit.pQhat = pQhat;
% %    
% 
% % plot the point cloud
% %-----------------------
% %    
% %    if plotfigs == true
% %    
% %       refpts   =  [ybar quantile(-dqdt,0.95)]; % late, early
% % 
% %       % the og version. blate=bhat, bestfit in legend (no b=1)
% %       h        =  bfra.pointcloudplot(q,dqdt,'blate',bhat,'mask',itau,    ...
% %                   'reflines',{'early','late','bestfit'},'reflabels',true, ...
% %                   'refpoints',refpts,'addlegend',true);
% %                   h.legend.AutoUpdate = 'off';
% %                   scatter(xbar,ybar,60,'k','filled','s');
% % 
% %       % new version. blate=1, bhat in legend (no bestfit)
% %       h        =  bfra.pointcloudplot(q,dqdt,'blate',1,'mask',itau,    ...
% %                   'reflines',{'early','late','userfit'},'reflabels',true, ...
% %                   'refpoints',refpts,'userab',[ahat bhat],'addlegend',true);
% %                   h.legend.AutoUpdate = 'off';
% %                   scatter(xbar,ybar,60,'k','filled','s');
% %    end
% %    
% %    if savedata == true
% %       fname = ['data/ppt/Events_' casenames{n} '.mat'];
% %       save(fname,'Events','Fits','K','TauFit','PhiFit','opts');
% %    end
% %    
% %    clear phidist
