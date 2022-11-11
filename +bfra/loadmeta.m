function Meta = loadmeta(basinname,varargin)
% LOADMETA load metadata for basin indicated by basinname

%------------------------------------------------------------------------------
   validopts = @(x)any(validatestring(x,{'current','archive'}));
   
   p                = inputParser;
   p.FunctionName   = 'bfra.loadmeta';
   addRequired(p, 'basinname',         @(x)ischar(x)  );
   addOptional(p, 'version','current', validopts      );
   parse(p,basinname,varargin{:});
   version = p.Results.version;
%------------------------------------------------------------------------------
   
   % load the meta data - use the one from 'Bounds'
   pathbounds  = [getenv('USERDATAPATH') 'interface/basins/matfiles/'];
   
   switch version
      case 'current'
         filebounds  = [pathbounds 'basin_boundaries.mat'];
      case 'archive'
         filebounds  = [pathbounds 'basin_boundaries_tmp.mat'];
   end
   load(filebounds,'Meta');

   % check for categorical station name
   if iscategorical(basinname); basinname = char(basinname); end
   
   % find the flow data
   allnames    =  lower(Meta.name);
   istation    =  ismember(allnames,lower(basinname));
   Meta        =  Meta(istation,:);