function [Calm,Meta] = loadcalm(basinname,varargin)
%LOADCALM loads calm ALT data for a basin in the Bounds struct

% since I think in terms of basins right now, not calm sites, this accepts
% the basin name not the calm site name

%------------------------------------------------------------------------------
   validopts = @(x)any(validatestring(x,{'current','archive'}));
   
   p              = inputParser;
   p.FunctionName = 'bfra.loadcalm';
   
   addRequired(p, 'basinname',            @(x) ischar(x)                   );
   addOptional(p, 'version',  'current',  validopts                        );
   addParameter(p,'t1',       NaT,        @(x) isdatetime(x)|isnumeric(x)  );
   addParameter(p,'t2',       NaT,        @(x) isdatetime(x)|isnumeric(x)  );
   
   parse(p,basinname,varargin{:});
   
   version  = p.Results.version;
   t1       = p.Results.t1;
   t2       = p.Results.t2;
%------------------------------------------------------------------------------

   % get the meta data
   if basinname == "ALL_BASINS"
      Meta = basinname;
   else
      Meta = bfra.loadmeta(basinname,version);
   end

   % load the calm data
   switch version
      case 'current'
         [Calm,Meta] = loadcalmcurrent(Meta);
      case 'archive'
         [Calm,Meta] = loadcalmarchive(Meta);
   end
   
   if ~isnat(t1)
      ok    = isbetween(Calm.Time,t1,t2);
      Calm  = Calm(ok,:);
   end

   
function [Calm,MetaCalm] = loadcalmcurrent(MetaBasin)

   % load the calm data
   fname = setpath('/interface/permafrost/matfiles/CALM_ALT.mat','data');
   
   load(fname,'Calm','Meta'); MetaCalm = Meta; clear Meta;
   
   if ~istable(MetaBasin) && MetaBasin == "ALL_BASINS"
      return
   end
   
   % find the calm data
   if MetaBasin.num_calm == 0
      error('no calm data for this basin')
   else
      % the indices of the calm sites for this basin
      idx   =  MetaBasin.idx_calm{:};
      Calm  =  Calm(:,idx);
      Meta  =  MetaCalm(idx,:);
      
%       % for the case of multiple sites, need to choose what to do
%       if numel(idx)>1
%          [Calm,Meta] = aggregateCalmData(Calm,Meta);
%       end
      
      % on second thought, I think we want to just return all the data and
      % deal with it on a case-by-case basis, fitting trends to all sites
      % with sufficient data, then average the trends rather than averaging
      % across sites here
      % i think we want this:
      % 1. synchronize all the sites
      % 2. eliminate sites with <10 years of data
      % 3. 

   end
   
   % temp hack to check against the og list
   sites = {'U11A','U11B','U11C','U12A','U12B','U13','U14','U32A','U32B'};
   keep  = ismember(Calm.Properties.VariableNames,sites);
   Calm  = Calm(:,keep);
   

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
      i1    = find(string(Calm.Properties.VariableNames) == "x1990");
      i2    = find(string(Calm.Properties.VariableNames) == "x2019");
      Dc    = table2array(Calm(MetaBasin.use_calm,i1:i2)); Dc = Dc';
      Calm  = timetable(Dc,'RowTimes',Tcalm);
   end
   
   
% function [Calm,Meta] = aggregateCalmData(Calm,Meta)
%    
%    % this stuff could be moved to bfra.loadcalm
%    % this converts all the site data into one timeseries with stats
%    Data     = timetablereduce(Data);
% 
%    macfig; 
%    trendplot(Data.Time,Data.mu,'useax',gca,'errorbars',true,'yerr',Data.sigma);
% 
%    % make a shapefile
%    [SE,CI,PM,mu,sigma] = stderr(transpose(table2array(Data)));
% 
%    S        = MetaCalm(Points.inpolyb,:);
%    S.avg    = mu;
%    S.std    = sigma;
%    S        = table2struct(tablecategorical2char(S));
%    S        = renameStructFields(S,{'LAT','LON'},{'Lat','Lon'});
%    S        = geopoint(S);
% 
% % %    this was here as an example of how i might write a function
% % bfra.writeshapefile
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% % save the data
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%    if saveshp == true
%       fsave    = [pathshp 'kuparuk_CALM.shp'];
%       writeGeoShapefile(S,fsave);
%    end
%    
% end

