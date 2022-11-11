function [Bounds,Meta,Poly] = loadbounds(basinname,varargin)

%------------------------------------------------------------------------------
   validopts = @(x)any(validatestring(x,{'current','archive'}));
   validproj = @(x)any(validatestring(x,{'ease','geo'}));
   
   p                = inputParser;
   p.FunctionName   = 'bfra.loadbounds';
   p.addRequired('basinname',                @(x)ischar(x)  );
   p.addParameter('projection',  'geo',      validproj      );
   p.addOptional( 'version',     'current',  validopts      );
   
   parse(p,basinname,varargin{:});
   
   basinname   = p.Results.basinname;
   projection  = p.Results.projection;
   version     = p.Results.version;
   
%------------------------------------------------------------------------------

   % load the basin boundaries and the flow data
   pathdata    = [getenv('USERDATAPATH') 'interface/basins/matfiles/'];

   % Nov 2022, checked this out from dev-bk, and copied below from current
   % version of loadmeta  
   switch version
      case 'current'
         filedata  = [pathdata 'basin_boundaries.mat'];
      case 'archive'
         filedata  = [pathdata 'basin_boundaries_tmp.mat'];
   end
   load(filedata,'Bounds','Meta');
   
   if strcmp(basinname,'ALL_BASINS')    % return all the basins
      
      % Meta     = Bounds.meta; % commented out nov 2022, instead load Meta
      Poly     = [Bounds.poly.(projection)];
      Bounds   = Bounds.(projection);
      
      % Sep 2, 2022, this was below this if/else/end, but seems like it
      % should only be applicable to this case, unless I pass in a list of
      % stations. if i get errors loading all the stations might need to
      % comment this out and test uncommenting the block below 
      
      % sort the Bounds, Meta, and Poly by station
      Meta     = sortrows(Meta,'station');
      [~,idx]  = sort({Bounds.Station}); 
      Bounds   = Bounds(idx(:));
      Poly     = Poly(idx(:));
      
   else

      % use ismember for exact match not contains
      allnames    = lower({Bounds.(projection).Name});
      idx         = find(ismember(allnames,lower(basinname)));
         
      if isempty(idx)
         error('basin not found, check name');
      else
         Poly     = Bounds.poly.(projection)(idx);
         Bounds   = Bounds.(projection)(idx,:);
         Meta     = Meta(idx,:);
      end
   end
         
%    % sort the Bounds, Meta, and Poly by station
%    Meta     = sortrows(Meta,'station');
%    [~,idx]  = sort({Bounds.Station}); 
%    Bounds   = Bounds(idx(:));
%    Poly     = Poly(idx(:));

% %  not sure what this was from
%    [~,idx] = sort({shp1.Station}); idx = idx'; 
%    shp1    = shp1(idx);
%    Bounds   = sort
   