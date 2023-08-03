function [Basins,Meta,Poly] = loadbasins(basinname,varargin)
%loadbasins load boundary object for basin specified by basinname
% 
% Syntax
% 
%     [Basins,Meta,Poly] = loadbasins(basinname,varargin)
% 
% Description
% 
%     Basins = bfra.loadbasins(basinname) returns struct Basins containing the
%     spatial basin boundary information.
% 
%     [Basins,Meta,Poly] = bfra.loadbasins(basinname) additionally returns table
%     Meta containing the basin metadata information and geoshape Poly
%     containing a computational geometry object representation of the basin
%     boundary.
% 
%     [Basins,Meta,Poly] = bfra.loadbasins(___,'projection',projtype) specifies
%     whether to return the basin boundary in geographic or projected
%     coordinates. Options are 'geo' and 'ease'. 'geo' is WGS 84. 'ease' is
%     NSIDC EASE North projection.
%
% 
% See also loadgrace, loadflow, loadcalm
% 
% Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% TODO: accept stationname. see loadcalm, it worked as soon as i added support
% for stationname to bfra.loadmeta meaning it relies entirely on the basinname
% returend by loadmeta, whereas this does not, because the Calm database has an
% entry for the basins or the index in Meta, so maybe doing that with boundaries
% would simplify thigns here.

% parse inputs
[basinname, version, projection] = parseinputs(basinname,varargin{:});

% load the basin metadata

% Nov 2022, checked this out from dev-bk, and copied below from current
% version of loadmeta  
switch version
   case 'current'
      filename = 'basin_boundaries.mat';
   case 'archive'
      filename = 'basin_boundaries_tmp.mat';
end
filename = fullfile(getenv('BASEFLOW_DATA_PATH'),'basins', filename);
load(filename, 'Bounds', 'Meta');

if strcmp(basinname,'ALL_BASINS')    % return all the basins

   % Meta = Bounds.meta; % commented out nov 2022, instead load Meta
   Basins = Bounds.(projection);
   Poly = [Bounds.poly.(projection)];

   % Sep 2, 2022, this was below this if/else/end, but seems like it
   % should only be applicable to this case, unless I pass in a list of
   % stations. if i get errors loading all the stations might need to
   % comment this out and test uncommenting the block below 

   % sort the Basins, Meta, and Poly by station
   Meta = sortrows(Meta,'station');
   [~,ii] = sort({Basins.Station}); 
   Basins = Basins(ii(:));
   Poly = Poly(ii(:));

else

   % use ismember for exact match not contains
   allnames = lower({Bounds.(projection).Name});
   ii = find(ismember(allnames,lower(basinname)));

   if isempty(ii)
      error('basin not found, check name');
   else
      Basins = Bounds.(projection)(ii,:);
      Poly = Bounds.poly.(projection)(ii);
      Meta = Meta(ii,:);
   end
end

% % sort the Bounds, Meta, and Poly by station
% Meta     = sortrows(Meta,'station');
% [~,idx]  = sort({Bounds.Station}); 
% Basins   = Bounds(idx(:));
% Poly     = Poly(idx(:));
% 
% %  not sure what this was from
% [~,idx] = sort({shp1.Station}); idx = idx'; 
% shp1    = shp1(idx);
% Basins   = sort

%% input parser
function [basinname, version, projection] = parseinputs(basinname,varargin)

validopts = @(x)any(validatestring(x,{'current','archive'}));
validproj = @(x)any(validatestring(x,{'ease','geo'}));

parser = inputParser;
parser.FunctionName = 'bfra.loadbasins';
parser.addRequired('basinname', @(x)ischar(x)|iscell(x));
parser.addOptional( 'version', 'current', validopts);
parser.addParameter('projection', 'geo', validproj);
parser.parse(basinname,varargin{:});

basinname   = parser.Results.basinname;
version     = parser.Results.version;
projection  = parser.Results.projection;