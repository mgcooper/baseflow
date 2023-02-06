function h = mapbasins(Basins,varargin)
%MAPBASINS map a set of basin boundaries and color their faces by an attribute
% 
% Syntax
% 
%     h = mapbasins(Basins,varargin)
% 
% Description
% 
%     h = mapbasins(Basins) creates a map-axes figure showing the basin outlines
%     for all basins in struct Basins.
% 
%     h = mapbasins(___,'varname',varname) colors the faces of the basins using
%     the value of variable varname. Basins must contain the data such that
%     cdata = Basins.(varname) returns the data. 
%
% Required inputs
% 
%     Basins   structure of basin boundaries
% 
% Optional inputs
% 
%     varname  variable to map face color, must match a 'basins' fieldname
% 
% Example
% 
%     h  = bfra.mapbasins(basins,'varname','perm_mean','cbartitle',    ...
%         'permafrost extent (%)','latlims',[65 80],'lonlims',[-168 -60]);
%
% See also mapgages, loadbounds
% 
% Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%     NOTE: use geo!
%     NOTE: variable name of cvar

%-------------------------------------------------------------------------------
p              = magicParser;
p.FunctionName = 'mapbasins';
p.StructExpand = false;

defaultvar = 'perm_mean';
defaulttxt = 'permafrost extent (%)';
defaultlatlims = [40 84]; % [50 75]
defaultlonlims = [-168 -40]; % [-168 -60]

p.addRequired( 'Basins',                              @(x)isstruct(x)   );
p.addParameter('Meta',        '',                     @(x)istable(x)    );
p.addParameter('facemapping', false,                  @(x)islogical(x)  );
p.addParameter('cvarname',    defaultvar,             @(x)ischar(x)     );
p.addParameter('cbartxt',     defaulttxt,             @(x)ischar(x)     );
p.addParameter('latlims',     defaultlatlims,         @(x)isnumeric(x)  );
p.addParameter('lonlims',     defaultlonlims,         @(x)isnumeric(x)  );
p.addParameter('proj',        'lambert',              @(x)ischar(x)     );
p.addParameter('facealpha',   0.35,                   @(x)isnumeric(x)  );
p.addParameter('facelabels',  false,                  @(x)islogical(x)  );
p.addParameter('ax',          gobjects,               @(x)isaxis(x)     );

p.parseMagically('caller');

if facemapping == true
   cvar = [Basins.(cvarname)];
end
usegeoshow = false; % need to add option or eliminate

% for lonlims, this owrks well for Alaska: [-170 -120]
%-------------------------------------------------------------------------------

if isstruct(Meta)
   Meta = struct2table(Meta);
end

% ensure that Basins and Meta contain the same basins and order
if ~isempty(Meta)
   Meta     = sortrows(Meta,'station');
   [~,idx]  = sort({Basins.Station});
   Basins   = Basins(idx(:));
   Basins   = Basins(ismember({Basins.Station},Meta.station));
end


% world borders has more detail than the ak state
borders = loadworldborders({'United States','Canada'},'merge');

coastlat = [ borders.Lat ];
coastlon = [ borders.Lon ];

h.figure = figure('Position',[1 1 1152 720]);
% h.map  = worldmap(latlims,lonlims);
% h.map  = worldmap('North Pole');
h.map    = axesm('MapProjection',proj,'MapLatLimit',latlims,'MapLonLimit',lonlims);
h.coast  = plotm(coastlat,coastlon,'LineWidth',1,'Color','k');
hold on;


% h.hworldmap     = worldmap('North America');
% h.hworldmap     = usamap('ak');
%h.hworldmap     = worldmap([45 90],[-58 -165]);
%h.hcoastlines   = plotm(borders.LAT,borders.LON,'LineWidth',1,'Color','k');

% setm(h.hworldmap,'MapLatLimit',latlims)
% setm(h.hworldmap,'MapLonLimit',lonlims)

%setm(h.hworldmap,'MapLatLimit',[45 72])
%setm(h.hworldmap,'MapLonLimit',[-168 -48])

if facemapping == true
   
   % remove nan ?
   
   cmin = min(cvar(:));
   cmax = max(cvar(:));
   
   if usegeoshow == true
      
      cspec = buildCspec(cvar,cmin,cmax);
      
      if isfield(Basins,'Lat')
         h.basins = geoshow(Basins,'SymbolSpec',cspec);
      elseif isfield(Basins,'X')
         h.basins = mapshow(Basins,'SymbolSpec',cspec);
      end
      
   else
      % nan goes last
      [cvar,idx] = sort(cvar);
      Basins = Basins(idx); % must sort or use basins(idx(n).lat in loop
      for n = 1:numel(Basins)
         latn  = [Basins(n).Lat];
         lonn  = [Basins(n).Lon];
         if isnan(cvar(n)) || cvar(n) == 0
            patchm(latn,lonn,'FaceVertexCData',[0.255 0.255 0.255],'FaceColor', ...
               'flat','FaceAlpha',0);
         else
            patchm(latn,lonn,'FaceVertexCData',cvar(n),'FaceColor','flat', ...
               'FaceAlpha',facealpha);
         end
      end
      ax = gca;
      % see notes on the patch sorting at end, but TLDR: the patchobjs are
      % ordered opposite the structure meaning patchobjs(1) = Basins(end),
      % patchobjs(2) = Basins(end-1), and so on. The flipud and sorting takes
      % care of all of the details. For testing, it was easier to not sort
      % Basins in the sortrows call below, but for labeling points, its needed.
      % Converting back to struct is only needed for consistency with other
      % parts of the code which assumes it is a struct.
      
      Basins = flipud(struct2table(Basins));
      [Basins,idx] = sortrows(Basins,'Area','ascend');
      Basins = table2struct(Basins);
      
      % this was the sort method before I added the flipud to simplify the
      % mapping from the Basins idx to the patchobjs idx.
      % we get the mapping from the cvar sort above to the Area sort next
      %[~,idx]     = sort([Basins.Area],'ascend');
      
      % right now, Basins are sorted from low to high cvar, so the index is
      % 1:numel(cvar), and the patchobjs are numel(cvar):-1:1, which means we
      % can use idx returned by sort on Basins.Area to reorder the patches
      lineobjs = findobj(ax.Children,'Type','Line');
      patchobjs = findobj(ax.Children,'Type','patch');
      
      if numel(patchobjs) ~= numel(Basins)
         % this occurs when the extent of the patches exceeds latlim/lonlim
         warning(['number of patch objects does not match number of basins' newline...
            'colorbar will not be accurate'])
      else
         ax.Children = [patchobjs(idx);lineobjs];
      end
      
      % this is not needed if we use 'ascend' to sort Area, but in other cases,
      % flipping the patchobjs is needed when manipulating them.
      %ax.Children = flipud([patchobjs(idx);lineobjs]);
   end
   
   % make the colorbar
   caxis([cmin cmax])
   
   %------------------------------------------------------
   % horizontal, south
   % h.cbar = colorbar('Location','southoutside');

   % this works for permfrost >50%
   % h.cbar.Position = [0.356 0.12 0.387 0.0256];
   
   %set(get(h.cbar,'title'),'string',ctxt,           ...
   %   'VerticalAlignment','baseline');
   %------------------------------------------------------
   
   h.cbar = discrete_colorbar(cvar,'nvals',10,'location','east');
  
   % this worked for the alaska domain
   % h.cbar.Position = [0.7 0.3 0.02 0.4];

   % but in general, use this
   h.cbar = colorbar('Location','east');
   
   h.cbar.AxisLocation = 'in'; 
   h.cbar.Label.String = cbartxt;
   
   % default text use tex, otherwise depends on whats passed in
   if contains(p.UsingDefaults,'cbartxt')
      %h.cbar.Label.Interpreter = 'tex'; 
   else
      h.cbar.Label.Interpreter = 'latex';
   end

   % for vertical cbar, we use Label not title
   %set(get(h.cbar,'title'),'string',ctxt,           ...
   %   'VerticalAlignment','baseline','HorizontalAlignment','left');
   
else
   
   % plot the basin outlines
   [latn,lonn] = polyjoin({Basins.Lat},{Basins.Lon});
   plotm(latn,lonn,'k','LineWidth',1);
   
%    for n = 1:numel(Basins)
%       latn = [Basins(n).Lat];
%       lonn = [Basins(n).Lon];
% 
%       % use patchm for consistency? or plotm for speed?
%       plotm(latn,lonn,'k');
%    end
   
% % I used this to confirm that the sorting by area after 
%    figure; plot([Basins(13).Lon],[Basins(13).Lat]); hold on;
%    for n = 1:numel(Basins)
%       plot([Basins(n).Lon],[Basins(n).Lat]);
%       pause;
%    end
   
end

if facelabels == true
   
   % add text labels
   ltxt  = round([Basins.(cvarname)],2);
   xpos  = nan(numel(ltxt),1);
   ypos  = nan(numel(ltxt),1);
   
   for n = 1:numel(ltxt)
      
      if ~isnan(ltxt(n))
         xpos(n) = quantile([Basins(n).Lon],0.25);
         ypos(n) = quantile([Basins(n).Lat],0.65);
         % blat = [Basins(n).Lat]; minlat = min(blat); maxlat = max(blat);
         % blon = [Basins(n).Lon]; minlon = min(blon); maxlon = max(blon);
         % xpos(n) = minlon + (maxlon-minlon)/10;
         % ypos(n) = minlat + (maxlat-minlat)/5;
      end
   end
   
   % jitter labels that overlap. get the total map x/y span in km
   xspan = (haversine([latlims(1),lonlims(1)],[latlims(1),lonlims(2)]) + ...
      haversine([latlims(2),lonlims(2)],[latlims(1),lonlims(2)]))/2;
   yspan = (haversine([latlims(1),lonlims(1)],[latlims(2),lonlims(1)]) + ...
      haversine([latlims(1),lonlims(2)],[latlims(2),lonlims(2)]))/2;

   % get dists between labels in km. 
   dists = nan(numel(ltxt),1);
   for n = 1:numel(ltxt)
      for m = 1:numel(ltxt)
         dists(m) = haversine([ypos(n),xpos(n)],[ypos(m),xpos(m)]);
      end
      
%       at this point I would need to jitter xpos(m),ypos(m) but i need to do it
%       systematically e.g. instead of using the quantiles above, need to use
%       opposite corners, but it will have to be iterative using while and
%       surely there's a better way but it's too coplicated for now
      reldists = dists./xspan;
      notok =  find(reldists < 0.025 & reldists > 0);
      if numel(notok) > 0
         xpos(n) = quantile([Basins(n).Lon],0.90);
         ypos(n) = quantile([Basins(n).Lat],0.90);
         for m = 1:numel(notok)
            xpos(notok(m)) = quantile([Basins(notok(m)).Lon],0.10);
            ypos(notok(m)) = quantile([Basins(notok(m)).Lat],0.10);
         end
      end
      % [xpos(notok) ypos(notok)]
   end
   

   for n = 1:numel(ltxt)

      if ~isnan(ltxt(n))
         textm(ypos(n),xpos(n),num2str(ltxt(n)),'FontSize',8, ...
            'Color',[0.8500 0.3250 0.0980]);         

%       xpos = quantile([Basins(n).Lon],0.20);
%       ypos = quantile([Basins(n).Lat],0.70);
%       xpos = mean([Basins(n).Lon],'omitnan');
%       ypos = mean([Basins(n).Lat],'omitnan');
%       xpos = median([Basins(n).Lon],'omitnan');
%       ypos = median([Basins(n).Lat],'omitnan');
%       xpos = min([Basins(n).Lon]);
%       ypos = max([Basins(n).Lat]);

      end
      
   end
   
end


% Make the colorbar transparent % https://stackoverflow.com/questions/37423603/setting-alpha-of-colorbar-in-matlab-r2015b
if facemapping == true
   drawnow;
   if facealpha<0.5
      alphaVal = min(1.0,facealpha + 0.20);
   else
      alphaVal = facealpha;
   end
   
   cdata = h.cbar.Face.Texture.CData;
   cdata(end,:) = uint8(alphaVal * cdata(end,:));
   h.cbar.Face.Texture.ColorType = 'truecoloralpha';
   h.cbar.Face.Texture.CData = cdata;
   drawnow
end

% once finished:
tightmap

% Make sure that the renderer doesn't revert your changes
% h.cbar.Face.ColorBinding = 'discrete';


% % Now change the ColorBinding back
% h.cbar.Face.ColorBinding = 'interpolated';
% 
% % Update the colormap to something new
% colormap(jet);
% drawnow
% 
% % Set the alpha values again
% cdata = h.cbar.Face.Texture.CData;
% cdata(end,:) = uint8(alphaVal * cdata(end,:));
% h.cbar.Face.Texture.CData = cdata;
% drawnow


% this works well for N. Ameria
%h.cbar.Position = [0.356 0.0588 0.387 0.0256];

% these worked before I changed LonLimit to what's above
%h.cbar.Position = [0.33 0.11755 0.38737 0.025641];

% % I used this to figure out the position above by guess and chekc
%     h.cbar.Position(3)=0.5*h.cbar.Position(3);
%     h.cbar.Position(1)=1.5*h.cbar.Position(1);
%     h.cbar.Position(2)=0.5*h.cbar.Position(2);

function cspec = buildCspec(cvar,cname,cmin,cmax)

cmap = parula(numel(cvar));
cspec = makesymbolspec('Polygon',{cname,[cmin cmax],  ...
   'FaceColor',cmap,                                  ...
   'FaceAlpha',0.95,                                  ...
   'LineWidth',0.5,                                   ...
   'EdgeColor','k'} );


% % notes on patch ordering:
% the patchobjs are ordered opposite the structure meaning patchobjs(1) =
% Basins(end), patchobjs(2) = Basins(end-1), and so on, so we flipud
% Basins first, then we get the new sort index by Area, going from low to
% high Area, and therefore when we reorder ax.Children using idx it orders
% the patches from high to low area since the patch order is opposite (for
% checking, it's easier to not sort Basins in the next line, that way
% Basins with nan cvar are first, and you can step through a loop plotting
% each basin boundary and see which ones are white in teh cvar map, then
% (in my test case) the big yukon basin was originally on top and you can
% see how a smaller one gets plotted on top when they're reordered and
% that's why we get more colors.
