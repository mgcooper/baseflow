clean

% ALTHOUGH KUPARUK LOOKS GREAT, THERE IS CLEARLY SOMETHING WROGN WITH THE EVENT
% DETECTION SEE THE EVENT RIGHT BEFORE THE CURRENT ONE, IT INCLUDES A PEAK, ALSO
% TEST VTS

load('data/MetaCalm.mat','Meta');
setpath('bfra_dev_bk','project');

pathsave    = setpath('interface/bfra/events/','data');

% set the main options
%----------------------
savedata    = true;
fitevents   = true;
fitglobal   = false;
fittrends   = false;
plotfigs    = false;
nsites      = height(Meta);

for n = 16:nsites

   sitename    = Meta.name{n};
   A           = Meta.area_m2(n);
   Dd          = 1000*Meta.Dd(n);
   D           = 0.5;
   L           = A*Dd/1000;

   % load the daily streamflow and meta data
   %-----------------------------------------
   Flow     = bfra_loadflow(sitename,'units','m3/d');
   T        = Flow.Time;
   Q        = Flow.Q;
   R        = zeros(size(T));

   % run the analysis
   %------------------

   % either run the algorithm or just load the data
   if fitevents == true

      % set opts
      %----------
      opts.Events = bfra.setopts('events','rmconvex',true);
      opts.Fits   = bfra.setopts('fits','drainagearea',A);

      % get events
      %------------
      % [Events]    = bfra.getevents(T,Q,R,opts.Events); 
      % numevents = numel(unique(Events.tag(~isnan(Events.tag))));
      
      [t,q,r,Info]   = bfra.findevents(T,Q,R,opts.Events);
      Events         = bfra.flattenevents(t,q,r,T,Q,R,Info);

      % fit events
      %------------
      [K,Fits]    = bfra.fitevents(Events,opts.Fits);

      %bfra_checkAllEvents(Events,Fits,K,opts.Events)
      
      if savedata == true
         save([pathsave 'events_' Meta.station{n} '.mat'],'Events','Fits','K','opts');
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

      opts.Global = bfra.setopts('globalfit','drainagearea',A,'aquiferdepth',D, ...
         'streamlength',L,'drainagedens',Dd,'isflat',true,'plotfits',true);

      GlobalFit = bfra.globalfit(K,Events,Fits,opts.Global);

      if savedata == true
         save(fname,'Events','Fits','K','GlobalFit','opts');
      end

   else
      
      if fittrends == true
         % load the saved analysis and take out the data needed to plot
         load(fname,'Events','Fits','K','GlobalFit','opts');
      end
   end

   % -----------------------------------------------
   %  compute baseflow and aquifer thickness trends
   % -----------------------------------------------
   if fittrends == true

      % load the active layer thickness data
      %--------------------------------------
      Calm  = bfra.loadcalm(sitename,'current');
      Calm  = timetablereduce(Calm);
      Calm  = Calm(:,{'mu','PM'});
      Calm  = renamevars(Calm,{'mu','PM'},{'Dc','sigDc'});
      % Calm  = retime(Calm,'yearly','previous');
   
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

      [Q,T]    = padtimeseries(Q,T,datenum(year(T(1)),1,1),datenum(year(T(end)),12,31),1);
      
      % compute baseflow and aquifer thickness
      %----------------------------------------
      [Qb,~,Qa,~,hb] = bfra.baseflowtrend(T,Q,A,'pctl',pQexp,'showfig',true); % cm/d/y
      [Db,Sb]  = bfra.aquiferthickness(bhat,tauexp,phihat,Qb,true); % cm/yr
      Qb       = Qb.*365.25;  % convert from cm/d/yr to cm/yr/yr


      % compute the combined uncertainty
      %---------------------------------
      [sig_dndt,sig_lambda] = bfra.dndtuncertainty(T,Qb,K,Fits,GlobalFit,opts.Global,0.05);
      % this is the uncertainty on Qb: hb.err

      % add to the GlobalFit
      %----------------------
      GlobalFit.Qb = Qb;
      GlobalFit.Db = Db;
      GlobalFit.Sb = Sb;


      % make separate tables for the Grace period and Calm period
      Data     = timetable(Q,'RowTimes',T);
      Data     = retime(Data,'regular','mean','TimeStep',calyears(1));
      Data     = retime(Data,'yearly','previous');
      %Data     = Data(2:end,:);
      Data     = addvars(Data,Qb,Sb,Db);
      Data     = synchronize(Data,Calm,Data.Time,'fillwithmissing');
      sigDb    = Data.Db.*sig_dndt;
      Data     = addvars(Data,sigDb);
      inanC    = isnan(Data.Dc);%  | isnan(Data.Q);
      DataC    = Data(~inanC,:);
      DataG    = DataC(find(year(DataC.Time)==2002):end,:);


      if savedata == true
         save(fname,'Events','Fits','K','GlobalFit','Data','DataC','DataG','opts');
      end



      % option to plot the alt trend
      %------------------------------
      if plotfigs == true
         bfra.plotalttrend(Data.Time,Data.Db,Data.sigDb);
         bfra.plotalttrend(DataC.Time,DataC.Db,DataC.sigDb,DataC.Dc,DataC.sigDc);
         bfra.plotalttrend(DataG.Time,DataG.Db,DataG.sigDb,DataG.Dc,DataG.sigDc);
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

   end

end