clean

% this script runs the entire analysis for the Kuparuk

% set the main options
%----------------------
savedata    = false;
fitevents   = false;
fitglobal   = true;
plotfigs    = true;
bootfit     = false;
nreps       = 1;

% this is the filename that will be used to save the output
fname       = 'data/Events.mat';

% load the daily streamflow and meta data
%-----------------------------------------
load('dailyflow.mat','T','Q','R');
load('annualdata.mat','Data');

% run the analysis
%------------------
% either run the algorithm or just load the data
if fitevents == true

   % set opts
   %----------
   opts.Events = bfra.setopts('events');
   opts.Fits   = bfra.setopts('fits','drainagearea',8.6545e9);

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
end

% ---------------------------------------------------------------------
%  run the global fitting analysis on the events or just load the data
% ---------------------------------------------------------------------

if fitglobal == true

   opts.Global = bfra.setopts('globalfit','drainagearea',8.6545e9, ...
               'aquiferdepth',0.5,'streamlength',320000,'isflat',true,...
               'plotfits',true);

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

% compute baseflow and aquifer thickenss
%----------------------------------------
[Qb,~,~,~,hb,ha] = bfra.baseflow(Data(:,1),Data(:,2),'pctl',pQexp,'show',false); % cm/d
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
   Data     = [Data,Db,Qb,Sb];
   inan     = isnan(Data(:,3));
   DataC    = Data(~inan,:);
   DataG    = Data(13:end,:);

   % compute trends in aquifer thickness
   f(3) = figure('Position',[6 241 512 384]);
   trendplot(DataC(:,1),DataC(:,3),'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataC(:,1),DataC(:,4),'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

   f(4) = figure('Position',[600 241 512 384]);
   trendplot(DataG(:,1),DataG(:,3),'units','cm/yr','use',gca,'leg','CALM');
   trendplot(DataG(:,1),DataG(:,4),'units','cm/yr','use',gca,'leg','BFRA');
   ylabel('active layer anomaly (cm/yr)');

end

GlobalFit.a

