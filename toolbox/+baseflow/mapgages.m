function h = mapgages(lat,lon,varargin)
   %MAPGAGES map a set of gage locations and color their faces by an attribute
   %
   % Syntax
   %
   %     h = mapgages(lat,lon,varargin)
   %
   % Description
   %
   %     h = mapgages(lat,lon) creates a map-axis figure showing the location of
   %     streamflow gage coordinates in lat,lon.
   %
   % Required inputs
   %
   %     lat,lon : vectors of latitude and longitude
   %     varname : variable to map face color, must match a 'gages' fieldname
   %
   % See also mapbasins
   %
   % Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % not sure if this function is deprecated by mapbasins, but I added the
   % parsing from that function in case it's worth keeping this

   % parse inputs
   [lat, lon, cvar, cbartitle, latlims, lonlims] = parseinputs( ...
      lat, lon, varargin{:});

   % --------------- load world borders
   borders = loadworldborders({'United States','Canada'},'merge');

   coastlat = [ borders.Lat ];
   coastlon = [ borders.Lon ];

   h.figure = figure;
   % h.map  = worldmap(latlims,lonlims);
   % h.map  = worldmap('North Pole');
   h.map = axesm('MapProjection',proj,'MapLatLimit',latlims,'MapLonLimit',lonlims);
   h.coast = plotm(coastlat,coastlon,'LineWidth',1,'Color','k');
   hold on;

   % % Old method before migrating updates from mapbasins
   % load coastlines.mat coastlat coastlon
   %
   % figure
   % h.h1 = worldmap(latlims,lonlims);
   % h.h2 = plotm(coastlat,coastlon,'LineWidth',1,'Color','k'); hold on;

   if ~isnan(cvar) % shade the circles by the provided variable
      h.gages = scatterm(lat,lon,20,cvar,'filled');
      h.cbar = colorbar;
      h.cbar = setcolorbar(h.cb,'Title',inputname(3));
   else
      h.gages = scatterm(lat,lon,20,'filled');
   end

   if isfield(h,'cbar')
      set(get(h.cbar,'title'),'string',cbartitle, ...
         'VerticalAlignment','baseline');
   end
end

%% INPUT PARSER
function [lat, lon, cvar, cbartitle, latlims, lonlims] = parseinputs( ...
      lat, lon, varargin)

   p = inputParser;
   p.FunctionName = 'baseflow.mapgages';
   p.addRequired('lat', @isnumeric);
   p.addRequired('lon', @isnumeric);
   p.addParameter('cvar', nan, @isnumeric);
   p.addParameter('cbartitle', '', @ischar);
   p.addParameter('latlims', [50 75], @isnumeric);
   p.addParameter('lonlims', [-168 -60], @isnumeric);
   p.addParameter('projstr', 'lambert', @ischar);
   p.addParameter('ax', gca, @isaxis);
   p.parse(lat, lon, varargin{:});

   lat = p.Results.lat;
   lon = p.Results.lon;
   cvar = p.Results.cvar;
   latlims = p.Results.latlims;
   lonlims = p.Results.lonlims;
   cbartitle = p.Results.cbartitle;
end
