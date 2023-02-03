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

%     NOTE: use geo!

% not sure if this function is deprecated by mapbasins, but I added the
% parsing from that function in case it's worth keeping this

%-------------------------------------------------------------------------------
p                = magicParser;
p.FunctionName   = 'mapgages';

p.addRequired( 'lat',                                 @(x)isnumeric(x)  );
p.addRequired( 'lon',                                 @(x)isnumeric(x)  );
p.addParameter('cvar',        nan,                    @(x)isnumeric(x)  );
p.addParameter('cbartitle',   '',                     @(x)ischar(x)     );
p.addParameter('latlims',     [50 75],                @(x)isnumeric(x)  );
p.addParameter('lonlims',     [-168 -60],             @(x)isnumeric(x)  );
p.addParameter('proj',        'lambert',              @(x)ischar(x)     );
p.addParameter('useax',       gca,                    @(x)isaxis(x)     );

p.parseMagically('caller');
%-------------------------------------------------------------------------------

% load world borders
borders = loadworldborders({'United States','Canada'},'merge');

coastlat = [ borders.Lat ];
coastlon = [ borders.Lon ];

h.figure = figure;
% h.map  = worldmap(latlims,lonlims);
% h.map  = worldmap('North Pole');
h.map    = axesm('MapProjection',proj,'MapLatLimit',latlims,'MapLonLimit',lonlims);
h.coast  = plotm(coastlat,coastlon,'LineWidth',1,'Color','k');
hold on;

% % Old method before migrating updates from mapbasins
% load coastlines.mat coastlat coastlon
% 
% figure
% h.h1  = worldmap(latlims,lonlims);
% h.h2  = plotm(coastlat,coastlon,'LineWidth',1,'Color','k'); hold on;

if ~isnan(cvar) % shade the circles by the provided variable
   h.gages = scatterm(lat,lon,20,cvar,'filled');
   h.cbar = colorbar;
   h.cbar = setcolorbar(h.cb,'Title',inputname(3));
else
   h.gages = scatterm(lat,lon,20,'filled');
end

if isfield(h,'cbar')
   set(get(h.cbar,'title'),'string',cbartitle,           ...
      'VerticalAlignment','baseline');
end
