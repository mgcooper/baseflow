clean

% this script runs the entire analysis for the Kuparuk

% i copied this so i could work quickly w/o committing but i think i got annoyed
% with it being in private so i moved it here 

% I think the current takeway is that we need to use the point cloud to get phi.
% otherwise we have the akwardness of combining b=1 and b=1.5 instead of using
% bhat. the tradeoff is we don't have phi sample for computing correlated
% uncertainties, but i've already determined the correlation hardly changes the
% uncertainty at all. A possible solution would be if using different lateqtls
% for eventphi wiht bhat helps. Note that using a smaller earlyqtls makes it
% worse, but need to check about lateqtls something like [0.5 0.3]

% set the main options
%----------------------
savedata    = true;
fitevents   = true;
fitglobal   = true;
plotfigs    = true;
bootfit     = true;
nreps       = 2000; % 2000
sitename    = bfra.basinname('SAGAVANIRKTOK R NR PUMP STA 3 AK');
Meta        = bfra.loadmeta(sitename);
A           = Meta.area_m2;
Dd          = Meta.Dd*1000;
D           = 0.5;
L           = A*Dd/1000;
phimethod   = 'pointcloud'; % 'distfit' 'pointcloud'
earlyqtls   = [0.95 0.95];
lateqtls    = [0.5 0.5];
refqtls     = [0.5 0.5];

% if D is prescribed to equal 0.47, we get back 0.45, and i don't think it's
% circular

% one more option to test: use median refqtls for ahat and phi point cloud, but
% early/lateqtls for eventphi

% added these back for loadcalm
t1       = datetime(1990,1,1);
t2       = datetime(2020,12,31);

% this is the filename that will be used to save the output
fname    = 'data/Events.mat';

% load the daily streamflow and meta data
%-----------------------------------------
load('data/dailyflow.mat','T','Q','R');
load('data/annualflow.mat','Data');

% load the active layer thickness data
%--------------------------------------
Calm  = bfra.loadcalm(sitename,'current','t1',t1,'t2',t2);
Calm  = timetablereduce(Calm);
Data  = synchronize(Data,Calm,Data.Time,'fillwithmissing');
Data  = renamevars(Data,'mu','Dc');

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
               
   opts.Global = bfra.setopts('globalfit','drainagearea',A,'aquiferdepth',D, ...
      'streamlength',L,'drainagedens',Dd,'isflat',true,'bootfit',bootfit, ...
      'nreps',nreps,'plotfits',true,'phimethod',phimethod,'earlyqtls', ...
      earlyqtls,'lateqtls',lateqtls,'refqtls',refqtls);

   GlobalFit = bfra.globalfit(K,Events,Fits,opts.Global);
   
% for the old fit:
%    load('data/Events_bk.mat','Events','Fits','K','GlobalFit','opts');
%       set(gca,'XLim',[0.72 175])

% for the new fit:
%    set(gca,'XLim',[0.72 400])
%    lobj = findobj('Type','legend');
%    lobj1 = lobj(1);
%    set(lobj1,'Position',[0.2 0.25 0.50664 0.10353])
%    % add (b) label then deselectfig
%    exportgraphics(gcf,'private/figs/taufit_plboot.png','Resolution',300)
   
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
ahat     = GlobalFit.a;
bhat     = GlobalFit.b;
tauexp   = GlobalFit.tau;
Qexp     = GlobalFit.Qexp;
phihat   = GlobalFit.phi;
pQexp    = GlobalFit.pQexp;

% for testing:
q        = GlobalFit.q;
dqdt     = GlobalFit.dqdt;
tau0     = GlobalFit.tau0;
itau     = GlobalFit.taumask;
Q0       = GlobalFit.Q0;

T        = Events.T;
Q        = Events.Q;

% compute baseflow and aquifer thickness
%----------------------------------------
[Qb,~,Qa,~,hb] = bfra.baseflowtrend(T,Q,A,'pctl',pQexp,'showfig',false); % cm/d/y
[Db,Sb]  = bfra.aquiferthickness(bhat,tauexp,phihat,Qb,true); % cm/yr
Qb       = Qb.*365.25;  % convert from cm/d/yr to cm/yr/yr


% compute the combined uncertainty
%---------------------------------
PhiFit = bfra.phifitensemble(K,Fits,A,D,L,bhat,lateqtls,earlyqtls,false);
[sig_dndt,sig_lambda] = bfra.dndtuncertainty(T,Qb,K,GlobalFit,PhiFit,0.05);
% this is the uncertainty on Qb: hb.err

% add to the GlobalFit
%----------------------
GlobalFit.Qb = Qb;
GlobalFit.Db = Db;
GlobalFit.Sb = Sb;


% make separate tables for the Grace period and Calm period
Data     = addvars(Data,Qb,Sb,Db);
sigDb    = Data.Db.*sig_dndt;
Data     = addvars(Data,sigDb);
inanC    = isnan(Data.Dc);%  | isnan(Data.Q);
DataC    = Data(~inanC,:);
sigDc    = Calm.PM;
DataC    = addvars(DataC,sigDc);
DataG    = DataC(find(year(DataC.Time)==2002):end,:);


if savedata == true
   save(fname,'Events','Fits','K','GlobalFit','Data','DataC','DataG','opts');
end
   


% option to plot the alt trend
%------------------------------
if plotfigs == true
   plotalttrend(Data.Time,Data.Db,Data.sigDb);
   plotalttrend(DataC.Time,DataC.Db,DataC.sigDb,DataC.Dc,DataC.sigDc);
   plotalttrend(DataG.Time,DataG.Db,DataG.sigDb,DataG.Dc,DataG.sigDc);
   plotalttrend(t,Db,sigDb,Dc,sigDc,varargin)
end

autoArrangeFigures(3,2,2)

% this uses the refqtls for late
[k,Q0,D,Dcheck] = bfra.aquiferprops(q,dqdt,ahat,bhat,phihat,A,D,L,'RS05', ...
   'mask',itau,'lateqtls',refqtls,'earlyqtls',earlyqtls,'Dd',Dd,'Q0',Q0);

% [k,Q0,D,Dcheck] = bfra.aquiferprops(q,dqdt,ahat,bhat,phihat,A,D,L,'RS05', ...
%    'mask',itau,'lateqtls',lateqtls,'earlyqtls',earlyqtls,'Dd',Dd,'Q0',Q0);

fprintf('\n ahat = %.7f \n',GlobalFit.a)
fprintf('\n pQexp = %.2f \n',GlobalFit.pQexp)
fprintf('\n D = %.2f \n',D)
fprintf('\n Dcheck = %.2f \n',Dcheck)


% convert alt trend to 'infilling' trend
0.31*0.037


% PhiFit = bfra.phifitensemble(K,Fits,A,D,L,bhat,lateqtls,earlyqtls,true);

%    % compute trends in aquifer thickness
%    figure('Position',[6 241 512 384]);
%    trendplot(DataC.Time,DataC.Dc,'units','cm/yr','use',gca,'leg','CALM');
%    trendplot(DataC.Time,DataC.Db,'units','cm/yr','use',gca,'leg','BFRA');
%    ylabel('active layer anomaly (cm/yr)');
% 
%    figure('Position',[600 241 512 384]); 
%    trendplot(DataG.Time,DataG.Dc,'units','cm/yr','use',gca,'leg','CALM');
%    trendplot(DataG.Time,DataG.Db,'units','cm/yr','use',gca,'leg','BFRA');
%    ylabel('active layer anomaly (cm/yr)');
