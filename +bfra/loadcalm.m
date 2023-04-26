function [Calm,Meta] = loadcalm(basinname,varargin)
%LOADCALM loads calm ALT data for a basin in the Bounds struct
% 
% Syntax
% 
%     [Calm,Meta] = loadcalm(basinname,varargin)
% 
% Description
% 
%     [Calm,Meta] = loadcalm(basinname) loads table Calm containing active layer
%     thickness data for basin basinname from the Circumpolar Active Layer
%     Monitoring program database, and metadata about the site Meta.
% 
%     [Calm,Meta] = loadcalm(__,'t1',t1,'t2',t2) returns table Calm for
%     the time period bounded by datetimes t1 and t2.
% 
% See also loadbounds, loadflow
% 
% Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% NOTE: does not support multiple basins, use loadcalm("All_Basins") and select
% since I think in terms of basins right now, not calm sites, this accepts
% the basin name not the calm site name

%------------------------------------------------------------------------------
validopts = @(x)any(validatestring(x,{'current','archive'}));

p = inputParser;
p.FunctionName = 'bfra.loadcalm';

addRequired(p, 'basinname',               @(x) bfra.validation.ischarlike(x));
addOptional(p, 'version',     'current',  validopts);
addParameter(p,'t1',          NaT,        @(x) bfra.validation.isdatelike(x));
addParameter(p,'t2',          NaT,        @(x) bfra.validation.isdatelike(x));
addParameter(p,'aggfunc',     'none',     @(x) bfra.validation.ischarlike(x));
addParameter(p,'minlength',   10,         @(x) bfra.validation.isnumericscalar(x));
addParameter(p,'mincoverage', 0.8,        @(x) bfra.validation.isnumericscalar(x));
addParameter(p,'minoverlap',  0.5,        @(x) bfra.validation.isnumericscalar(x));
addParameter(p,'maxdiff',     0.5,        @(x) bfra.validation.isnumericscalar(x));

parse(p,basinname,varargin{:});

basinname   = char(basinname);
version     = p.Results.version;
t1          = p.Results.t1;
t2          = p.Results.t2;
aggfunc     = p.Results.aggfunc;

% these parameters control whether or not we accept the average of all sites
% when multiple sites exist within a basin. Sites that do not satisfy these
% parameters are removed. 
minlength   = p.Results.minlength;     % minimum record length (# of values)
mincoverage = p.Results.mincoverage;   % percent coverage (# of values / # years)
minoverlap  = p.Results.minoverlap;    % percent overlap (like coverage but between sites)
maxdiff     = p.Results.maxdiff;       % percent difference in trend between sites
%------------------------------------------------------------------------------

% get the meta data
if ~istable(basinname) && basinname == "ALL_BASINS"
   MetaBasin = basinname;
else
   MetaBasin = bfra.loadmeta(basinname,version);
end

% load the calm data
switch version
   case 'current'
      [Calm,Meta] = loadcalmcurrent(MetaBasin);
   case 'archive'
      [Calm,Meta] = loadcalmarchive(MetaBasin);
end

if ~isnat(t1)
   ok = isbetween(Calm.Time,t1,t2);
   Calm = Calm(ok,:);
end

[Calm,Meta] = aggregateCalm(Calm,Meta,aggfunc,minlength,mincoverage,minoverlap,maxdiff);

% add the basiname to the Calm Meta table
if basinname ~= "ALL_BASINS"
   Meta.basin = repmat(categorical({basinname}),height(Meta),1);
   Meta.station = repmat(categorical(MetaBasin.station),height(Meta),1);
end

% % if requested, aggregate the multi-site data
% switch aggfunc
%    case 'avg'
%       Calm = aggregateCalm(Calm,Meta,minlength,mincoverage,minoverlap,maxdiff);
%    case 'robust'
%       [Calm,Meta] = aggregateCalm(Calm,Meta,minlength,mincoverage,minoverlap,maxdiff);
% end

% if case 'avg' with timetablereduce is problematic, this was the original method
%Time  = Calm.Time;
%Dc    = nanmean(table2array(Calm),2);
%Calm  = array2timetable(Dc,'RowTimes',Time);



function [Calm,Meta] = aggregateCalm(Calm,Meta,aggfunc,minlength,mincoverage,minoverlap,maxdiff)

% outside of this function, we can decide to fit trends to all sites that pass
% the filters and then average those trends versus fitting to the average across sites

switch aggfunc 
   case 'none'
      return
      
   case 'avg'
      % 'avg' might as well return PM. previously 'bfra'
      Calm = bfra.util.timetablereduce(Calm);
      Calm = Calm(:,{'mu','PM'});
      Calm = renamevars(Calm,{'mu','PM'},{'Dc','sigDc'});
      return
      
   case 'robust'

      ok = Meta.nyears>=minlength & Meta.coverage>=mincoverage;

      % if no sites have > minlength values, set nan and return
      if sum(ok)==0
         Calm.Dc = nan(height(Calm),1);
         Calm.sigDc = nan(height(Calm),1);
         Calm = Calm(:,{'Dc','sigDc'});
         return
      elseif sum(ok)==1
         % if one site has > minlength values, call case 'avg' and return
         Calm = Calm(:,ok);
         Meta = Meta(ok,:);
         Calm = aggregateCalm(Calm,Meta,'avg',minlength,mincoverage,minoverlap,maxdiff);
         return
      end

      % remove sites with < minlength
      Calm = Calm(:,ok);
      Meta = Meta(ok,:);

      % use the longest record as the reference site
      nsites = height(Meta);
      nyears = Meta.nyears;
      nmax = max(nyears);
      iref = nyears == nmax;
      
      % get the trend using the longest record and then using the average
      alldata = table2array(Calm);
      mu = mean(alldata,2,'omitnan');
      Trends = timetabletrends(addvars(Calm,mu));

      % the trend slopes are added as custom props in timetable trend but the last one
      % is the "TimeX" regressor variable which is set nan
      slopes = Trends.Properties.CustomProperties.TrendSlope(1:end-1);
      tseries = table2array(Trends(:,1:end-1));
      
      % this handles the case with more than one "reference site"
      refslope = mean(slopes(iref));

      % if the trend of the average is less than X% different than the trend of the
      % longest record, then don't worry about overlap, use the average timeseries
      if abs(1-slopes(end)/refslope) < maxdiff
         Calm = aggregateCalm(Calm,Meta,'avg',minlength,mincoverage,minoverlap,maxdiff);
         return
      end
      % if here, all sites have minlength, mincoverage, but when averaged, their
      % trend is more than maxdiff percent different from the trend of the
      % reference site. If this is due to spatial variability, that's ok, but if
      % it's due to temporal mismatch, like one site has 12 years of data from
      % 1990-2002 and the other sites have 20 years from 2000-2020, then we
      % exclude the one from 1990-2002 based on the minoverlap parameter, i.e.
      % we remove sites that do not overlap with all other sites by minoverlap
      % in percent terms relative to the total number of years.
      
      % determine overlap. simplest method: ok = nyears./nmax > minoverlap;
      % better method: get actual overlap of each site relative to the ref site.
      % this works if iref has more than one site.
      overlap = nan(nsites,1);
      for n = 1:nsites
         overlap(n) = sum(all(~isnan([alldata(:,iref),alldata(:,n)]),2))/nmax;
      end
      ok = overlap > minoverlap;
      
      % select the sites that qualify and call the 'avg' case
      Calm = Calm(:,ok);
      Meta = Meta(ok,:);
      Calm = aggregateCalm(Calm,Meta,'avg',minlength,mincoverage,minoverlap,maxdiff);
      
      % for debugging:
      plottrends = false;
      if plottrends == true 
         figure; plot(Calm.Time,alldata,'-o'); hold on;
         plot(Calm.Time,mean(alldata,2,'omitnan')); set(gca,'ColorOrderIndex',1)
         plot(Calm.Time,tseries); bfra.util.formatPlotMarkers;
         legend(Trends.Properties.VariableNames(1:end-1),'Location','best');
         
         % this was in the aggregateCalmData temporary function i deleted
         bfra.trendplot(Data.Time,Data.mu,'useax',gca, ...
            'errorbars',true,'yerr',Data.sigma);
      end
      
      % NOTE:
      % say one site has values every other year, then the overlap is only 50%,
      % but it may be good data. Return to that edge case if needed. For now,
      % use total overlap. Besides, in that case, the data will be retained if
      % the trends are not more than maxdiff apart. 
      
      % Regarding maxdiff check: two checks are considered: 1) is the trend of
      % any individual site more than x% different than the site with the
      % longest record? and 2) is the trend of the average of all sites more
      % than x% different than the site with the longest record? The second
      % method is implemented. The first method would require this:
      
      % ok = abs(slopes(1:end-1)-slopes(iref))./slopes(iref) < maxdiff;
end


% there was a note about using this to make a function bfra.writeshapefile but
% it could also be used to find calm sites within a given boundary on the fly,
% e.g. if I want to expand my search programatically using this function, I
% could pass in the basin shapefile and a buffer tolerance and find all sites
% within that buffer, whcih would also be useful for finding rain stations

% % make a shapefile
% [SE,CI,PM,mu,sigma] = stderr(transpose(table2array(Data)));
% 
% S = MetaCalm(Points.inpolyb,:);
% S.avg = mu;
% S.std = sigma;
% S = table2struct(tablecategorical2char(S));
% S = renamestructfields(S,{'LAT','LON'},{'Lat','Lon'});
% S = geopoint(S);




      
function [Calm,Meta] = loadcalmcurrent(MetaBasin)

% load the calm data
fname = setpath('/interface/permafrost/matfiles/CALM_ALT.mat','data');

load(fname,'Calm','Meta');

if ~istable(MetaBasin) && MetaBasin == "ALL_BASINS"
   return
end

MetaCalm = Meta; clear Meta;

% find the calm data
if MetaBasin.num_calm == 0
   error('no calm data for this basin')
else
   % the indices of the calm sites for this basin
   idx = MetaBasin.idx_calm{:};
   Calm = Calm(:,idx);
   Meta = MetaCalm(idx,:);
   
   % add number of valid years and start/end 
   keep = ~isnan(table2array(Calm));
   nyears = transpose(sum(keep));
   ibegin = transpose(table2array(varfun(@(A)(find(~isnan(A),1,'first')),Calm)));
   ifinal = transpose(table2array(varfun(@(A)(find(~isnan(A),1,'last')),Calm)));
   ybegin = year(Calm.Time(ibegin));
   yfinal = year(Calm.Time(ifinal));
   tcover = round(nyears./(yfinal-ybegin+1),2);
   Meta = addvars(Meta,nyears,ybegin,yfinal,tcover,'NewVariableNames', ...
      ["NumYears","YearStart","YearEnd","Coverage"]);
end

% temp hack to check against the og list
if strcmp(MetaBasin.name,'KUPARUK R NR DEADHORSE AK')
   sites = {'U11A','U11B','U11C','U12A','U12B','U13','U14','U32A','U32B'};
   keep = ismember(Calm.Properties.VariableNames,sites);
   Calm = Calm(:,keep);
   Meta = Meta(keep,:);
end

function [Calm,MetaBasin] = loadcalmarchive(MetaBasin)

fname = setpath('interface/permafrost/alt/CALM/archive/CALM_ALT.mat','data');

load(fname,'Calm','Tcalm');

if ~istable(MetaBasin) && MetaBasin == "ALL_BASINS"
   return
end

% find the calm data
if isempty(MetaBasin.sites_calm)
   error('no calm data for this basin')
else
   i1 = find(string(Calm.Properties.VariableNames) == "x1990");
   i2 = find(string(Calm.Properties.VariableNames) == "x2019");
   Dc = table2array(Calm(MetaBasin.use_calm,i1:i2)); Dc = Dc';
   Calm = timetable(Dc,'RowTimes',Tcalm);
end
