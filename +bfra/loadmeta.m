function Meta = loadmeta(basinname,varargin)
% LOADMETA load metadata for basin indicated by basinname

%------------------------------------------------------------------------------
   p                = MipInputParser;
   p.FunctionName   = 'bfra.loadmeta';
   p.addRequired('basinname',@(x)ischar(x));
   p.addOptional('version','current',@(x)ischar(x));
   p.parseMagically('caller');
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