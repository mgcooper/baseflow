function h = mapgages(lat,lon,varargin)

% not sure if this function is deprecated by mapbasins, but I added the
% parsing from that function in case it's worth keeping this

%-------------------------------------------------------------------------------
p                = magicParser;
p.FunctionName   = 'mapgages';

p.addRequired( 'lat',                                 @(x)isnumeric(x)  );
p.addRequired( 'lon',                                 @(x)isnumeric(x)  );
p.addParameter('cvar',        nan,                    @(x)isnumeric(x)  );
p.addParameter('cbartitle',   '',                     @(x)ischar(x)     );
p.addParameter('latlims',     [45 90],                @(x)isnumeric(x)  );
p.addParameter('lonlims',     [-58 -165],             @(x)isnumeric(x)  );
p.addParameter('useax',       gca,                    @(x)isaxis(x)     );

p.parseMagically('caller');
%-------------------------------------------------------------------------------


load coastlines.mat coastlat coastlon

figure
h.h1  = worldmap(latlims,lonlims);
h.h2  = plotm(coastlat,coastlon,'LineWidth',1,'Color','k'); hold on;

if ~isnan(cvar) % shade the circles by the provided variable
   h.h3   = scatterm(lat,lon,20,cvar,'filled');
   h.cbar = colorbar;
   h.cbar = setcolorbar(h.cb,'Title',inputname(3));
else
   h.h3   = scatterm(lat,lon,20,'filled');
end

if isfield(h,'cbar')
   set(get(h.cbar,'title'),'string',cbartitle,           ...
      'VerticalAlignment','baseline');
end
