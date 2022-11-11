clean

% this script runs the entire analysis for the Kuparuk

% set the main options
%----------------------
savedata    = false;
fitevents   = true;
fitglobal   = true;
plotfigs    = true;
bootfit     = false;
nreps       = 1;
sitename    = bfra.basinname('KUPARUK R NR DEADHORSE AK');
A           = 8.6545e9;
D           = 0.5;

% this is the filename that will be used to save the output
fname       = 'data/Events.mat';

% load the daily streamflow and meta data
%-----------------------------------------
load('dailyflow.mat','T','Q','R');
load('annualflow.mat','Data');

% load the active layer thickness data
%--------------------------------------
Calm  = bfra.loadcalm(sitename,'archive');
Calm  = retime(Calm,'yearly','next'); Calm.Dc(end) =  42.571;
Data  = synchronize(Data,Calm,Data.Time,'fillwithmissing');

% run the analysis
%------------------

% either run the algorithm or just load the data
if fitevents == true

   % set opts
   %----------
   opts.Events = bfra.setopts('events');
   opts.Fits   = bfra.setopts('fits','drainagearea',A);
   
   % get events
   %------------
   [Events]    = bfra.getevents(T,Q,R,opts.Events); 

   % fit events
   %------------
   [K,Fits]    = bfra.fitevents(Events,opts.Fits);

   if savedata == true
      save(fname,'Events','Fits','K','opts');
   end

else
   % load the data
   %---------------
   load(fname,'Events','Fits','K','opts');

   if istable(K)
      K = table2struct(K);
   end
end

% ---------------------------------------------------------------------
%  run the global fitting analysis on the events or just load the data
% ---------------------------------------------------------------------

if fitglobal == true
               
   opts.Global = bfra.setopts('globalfit','drainagearea',A, ...
               'aquiferdepth',D,'streamlength',320000,'isflat',true,...
               'bootfit',true,'nreps',2000,'plotfits',true);

   GlobalFit = bfra.globalfit(K,Events,Fits,opts.Global);
   
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
T     = Events.T;
Q     = Events.Q;

% compute baseflow and aquifer thickness
%----------------------------------------
[Qb,~,Qa] = bfra.baseflowtrend(T,Q,A,'pctl',pQexp,'showfig',false); % cm/d/y
[Db,Sb]  = bfra.aquiferthickness(bhat,tau,phi,Qb,true); % cm/yr
Qb       = Qb.*365.25;  % convert from cm/d/yr to cm/yr/yr

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
   DataG    = PlotData(find(year(PlotData.Time)==2002):end,:);

   % compute trends in aquifer thickness
   figure('Position',[6 241 512 384]);
   trendplot(DataC.Time,DataC.Dc,'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataC.Time,DataC.Db,'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

   figure('Position',[600 241 512 384]); 
   trendplot(DataG.Time,DataG.Dc,'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataG.Time,DataG.Db,'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

end

GlobalFit.a
GlobalFit.pQexp

autoArrangeFigures(3,2,2)
