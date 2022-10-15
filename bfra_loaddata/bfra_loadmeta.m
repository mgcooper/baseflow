function Meta = bfra_loadmeta(basinname)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p                = MipInputParser;
   p.FunctionName   = 'bfra_loadmeta';
   p.addRequired('basinname',@(x)ischar(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   % load the meta data - use the one from 'Bounds'
   pathbounds  = '/Users/coop558/MATLAB/INTERFACE/data/recession/basins/';    
   filebounds  = [pathbounds 'basin_boundaries.mat'];
   
   load(filebounds,'Meta');

   % check for categorical station name
   if iscategorical(basinname); basinname = char(basinname); end
   
   % find the flow data
   allnames    =  lower(Meta.name);
   istation    =  ismember(allnames,lower(basinname));
   Meta        =  Meta(istation,:);