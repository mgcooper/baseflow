function GHCN = bfra_loadghcnd(basinname,varargin)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p=MipInputParser;
   p.FunctionName='bfra_loadghcnd';
   p.PartialMatching=true;
   p.addRequired('basinname',@(x)ischar(x));
   p.addParameter('t1',NaT,@(x) isdatetime(x)|isnumeric(x));
   p.addParameter('t2',NaT,@(x) isdatetime(x)|isnumeric(x));
   p.addParameter('units',NaN,@(x) ischar(x));
   p.addParameter('gapfill',false,@(x) islogical(x));
   p.parseMagically('caller');
   
   if isnumeric(t1) %#ok<*NODEF>
      t1 = datetime(t1,'ConvertFrom','datenum');
      t2 = datetime(t2,'ConvertFrom','datenum');
   end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   % to get this to a full fledged function, i could use lat,lon + radius
   % and query the ghcdn metadata to find stations
   
   % check for categorical station name
   if iscategorical(basinname); basinname = char(basinname); end

   if strcmp(basinname,'KUPARUK R NR DEADHORSE AK') == false
      error('only functional for Kuparuk at present')
   end
         
   % this replaces the commented stuff above
   GHCN = readGHCND('station','USC00505136');
   GHCN = retime(GHCN,'daily','fillwithmissing');

% % old method:   
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %    
%    % load the rain data
%    pathrain    = '/Users/coop558/mydata/interface/weather/matfiles/';
%    filerain    =  [pathrain 'kuparukMetDataGHCND'];
%    load(filerain,'data'); 
%    
%    % for now this will only work with Kupariuk
%    Rain        = data.KUPARUK; clear data;
%    Rain        = renamevars(Rain,'PRCP_mm_','rain');
%    rmvars      = {'PRCP_measurement_flag','PRCP_quality_flag','PRCP_source_flag'};
%    Rain        = removevars(Rain,rmvars);
%    Rain        = retime(Rain,'daily','fillwithmissing');
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %   

   % trim the data to the requested time period
   if isnat(t1)
      si = find(~isnan(GHCN.PRCP),1,'first');
      ei = find(~isnan(GHCN.PRCP),1,'last');
      iok = si:ei;
   else
      iok = isbetween(GHCN.Time,t1,t2);
   end
   % the t1/t2 method might remove the need for padding/trimming
   GHCN = GHCN(iok,:);
   
   % the iok thing means we don't need to trimtimetable, but still need to pad
   if GHCN.Time(1)>t1 || GHCN.Time(end)<t2
      Time = t1:caldays(1):t2;
      GHCN = retime(GHCN,Time,'fillwithmissing');
   end
   
   ileap = month(GHCN.Time) == 2 & day(GHCN.Time) == 29;
   GHCN(ileap,:) = [];
   
   % % first i made Rain with the new method, then saved it as keep:
   % figure; myscatter(GHCN.PRCP,keep.PRCP./10); addOnetoOne;
   
   if gapfill == true
      numyears =  height(GHCN)/365;
      prcp     =  transpose(reshape(GHCN.PRCP,365,numyears));
      try 
         prcp  =  fillgaps(prcp);
      catch ME
         % check for signal processing toolbox checkout error
         if strcmp(ME.identifier,'MATLAB:license:checkouterror')
            
            % set nan to zero. it probably isn't justified to use any gap
            % filling method without nearby station or model data,
            % inclduing the ar gapfilling above, but for now, set zero 
            prcp(isnan(prcp)) = 0;
            % rain = fillmissing(rain);
         end
      end
         
      prcp        =  reshape(transpose(prcp),numyears*365,1);
      notOK       =  prcp<0;
      prcp(notOK) =  0;
      GHCN.PRCP   = prcp;
   end
   
   % rain comes in as mm/day
%    GHCN.PRCP   = GHCN.PRCP./10.*ddperyy;
   
   if notnan(units)
%       aream2   =  Meta.darea.*1e6;
      vars  = {'PRCP','SNOW','SNWD'};
      for n = 1:numel(vars)
         
         switch units
            case 'mm/d'
               % do nothing
            case 'cm/d'
               GHCN.(vars{n}) = GHCN.(vars{n})./10;
            case 'm/d'
               GHCN.(vars{n}) = GHCN.(vars{n})./1000;
            case 'mm/y'
               GHCN.(vars{n}) = GHCN.(vars{n}).*365.25;
            case 'cm/y'
               GHCN.(vars{n}) = GHCN.(vars{n})./10.*365.25;
            case 'm/y'
               GHCN.(vars{n}) = GHCN.(vars{n})./1000.*365.25;
            case 'm3/d'

            case 'm3/y'

            case 'km3/y'
         end
      end

      units = {units};
      
      for n = 1:numel(vars)
         idx = find(strcmp(GHCN.Properties.VariableNames,vars{n}));
         GHCN.Properties.VariableUnits(idx) = units;
      end
      
   else
      units = {'mm/d'};
   end
  
% % readGHCND sets the units so only reset if converted
%    % flow is in m3/s, so set that here
%    for n = 1:numel(vars)
%       idx = find(strcmp(GHCN.Properties.VariableNames,vars{n}));
%       GHCN.Properties.VariableUnits(idx) = units;
%    end

% % to check pre-post gap fill   
%  figure; plot(GHCN.Time,GHCN.PRCP); hold on; plot(GHCN.Time,GHCN./10.*365.25,':');
   
% % these were in read_flow script to check but don't work anymore   
% % these check post retime, pre synch
% [RainM.PRCP(1) mean(GHCN.PRCP(1:28))] % feb is first month
% [RainM.PRCP(end) mean(GHCN.PRCP(end-30:end))]

% check again
% [RainA.PRCP(1) mean(RainM.PRCP(1:12))]
% [RainA.PRCP(end) mean(RainM.PRCP(end-11:end))]
   
   
   
   
   
