
function h = figformat(varargin)

% the problem with the current add second axis function is that i can't add
% new plots to the figure, they are hidden behind the data. 
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
p                 = magicParser;
p.FunctionName    = 'figformat';
p.CaseSensitive   = false;
p.KeepUnmatched   = true;

p.addParameter(    'reformat',           false,      @(x)islogical(x)  );
p.addParameter(    'textfontsize',       14,         @(x)isscalar(x)   );
p.addParameter(    'axesfontsize',       16,         @(x)isscalar(x)   );
p.addParameter(    'labelfontsize',      16,         @(x)isscalar(x)   );
p.addParameter(    'legendfontsize',     14,         @(x)isscalar(x)   );
p.addParameter(    'textfontname',       'verdana',  @(x)ischar(x)     );
p.addParameter(    'axesfontname',       'verdana',  @(x)ischar(x)     );
p.addParameter(    'labelfontname',      'verdana',  @(x)ischar(x)     );
p.addParameter(    'legendfontname',     'verdana',  @(x)ischar(x)     );
p.addParameter(    'legendlocation',     'best',     @(x)ischar(x)     );
p.addParameter(    'textinterpreter',    'latex',    @(x)ischar(x)     );
p.addParameter(    'axesinterpreter',    'latex',    @(x)ischar(x)     );
p.addParameter(    'labelinterpreter',   'latex',    @(x)ischar(x)     );   
p.addParameter(    'legendinterpreter',  'latex',    @(x)ischar(x)     );
p.addParameter(    'linelinewidth',      1,          @(x)isscalar(x)   );
p.addParameter(    'axeslinewidth',      1,          @(x)isscalar(x)   );
p.addParameter(    'patchlinewidth',     1,          @(x)isscalar(x)   );
p.addParameter(    'ticklength',         [.015 .02], @(x)isnumeric(x)  );
p.addParameter(    'suppliedfigure',     gcf,        @(x)isobject(x)   );
p.addParameter(    'suppliedaxis',       nan,        @(x)isaxis(x)     );
p.addParameter(    'suppliedline',       [],         @(x)ishandle(x)   );
p.addParameter(    'xgrid',              'on',       @(x)ischar(x)     );
p.addParameter(    'ygrid',              'on',       @(x)ischar(x)     );
p.addParameter(    'xgridminor',         'off',      @(x)ischar(x)     );
p.addParameter(    'ygridminor',         'off',      @(x)ischar(x)     );

p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   suppliedaxis = p.Results.suppliedaxis;
   
   % if an axis is provided, only apply settings to that object (note that 
   % some settings cannot be controlled axis-by-axis so mileage will vary)
   setaxisonly    = false;
   if ~isaxis(suppliedaxis)
      suppliedaxis   = gca;
   else
      setaxisonly    = true;
   end

   %    switch p.Results.reformat
   %       case true
   %          h = refigformat(p);
   %       case false
   %          h = newfigformat(p);
   %    end
   % end
   % 
   % 
   % function h = newfigformat(p)

   %    p.parseMagically('caller');

   unmatched = p.Unmatched;

   % might use this:
   % allChildren    = findobj(allchild(gcf));
   % htext    = findobj(allChildren,'Type','Text') 

   %~~~~~~~~~~~~~~~~~~~~
   % GENERAL PROPERTIES
   %~~~~~~~~~~~~~~~~~~~~

   % I turned all of these off b/c they are set now in startup
   % set(findall(gcf,'-property','LineWidth'),'LineWidth',1);
   % set(findall(gcf,'-property','FontSize'),'FontSize',16)
   % set(findall(gcf,'-property','TickDir'),'TickDir','out')
   % set(findall(gcf,'-property','XMinorTick'),'XMinorTick','on')
   % set(findall(gcf,'-property','YMinorTick'),'YMinorTick','on')

   % except these
   %    set(findall(gcf,'-property','TickLabelInterpreter'),'TickLabelInterpreter',labelinterpreter);
   %    set(findall(gcf,'-property','Interpreter'),'Interpreter',axesinterpreter);

   %~~~~~~~~~~~~~~~~~~~~
   % AXES PROPERTIES
   %~~~~~~~~~~~~~~~~~~~~
   
   % test - setting to 'outerposition' should prevent x/ylabel cutoff
   istiled = false;
   try
      lastwarn('');
      set(suppliedaxis,'PositionConstraint','outerposition'); %'innerposition'
      [warnMsg, warnId] = lastwarn;
      if ~isempty(warnMsg)
        istiled = true;
      end
   catch ME
      
   end
   % see: https://www.mathworks.com/help/matlab/creating_plots/automatic-axes-resize.html

   suppliedaxis.YLabel.Interpreter = labelinterpreter;
   suppliedaxis.XLabel.Interpreter = labelinterpreter;
   set(suppliedaxis,'FontName',axesfontname);
   set(suppliedaxis,'FontSize',axesfontsize);
   set(suppliedaxis,'LineWidth',axeslinewidth);
   set(suppliedaxis,'TickLabelInterpreter',axesinterpreter)
   set(suppliedaxis,'TickLength',ticklength);
   set(suppliedaxis,'XGrid',xgrid);
   set(suppliedaxis,'YGrid',ygrid);
   set(suppliedaxis,'XMinorGrid',xgridminor);
   set(suppliedaxis,'YMinorGrid',ygridminor);

   %    % it might be necessary to do this if we have multiple axes, b/c the
   %    default suppliedaxis is gca
   %    hAxes    = findobj(gcf,'Type','Axes');
   %    set(hAxes,'FontName',axesfontname);
   %    set(hAxes,'FontSize',axesfontsize);
   %    set(hAxes,'LineWidth',axeslinewidth);
   %    set(hAxes,'TickLabelInterpreter',axesinterpreter)
   %    set(hAxes,'TickLength',ticklength);

   
   % new:
   if strcmp(suppliedaxis.XScale,'log') 
      if strcmp(suppliedaxis.YScale,'log') 
         setlogticks(suppliedaxis,'axset','xy');
      else
         setlogticks(suppliedaxis,'axset','x');
      end
   elseif strcmp(suppliedaxis.YScale,'log') 
      setlogticks(suppliedaxis,'axset','y');
   end
   

   % other axis props:
   % Box, Color, Colormap, FontAngle, GridAlpha, GridColor, etc.
   % XAxis, XAxisLocation, XColor, XDir, XGrid, XLabel, XLim, XMinorGrid,
   % XMinorTick, XScale, XTick, XTickLabel, XTickLabelRotation

   hLegend = [];
   if isfield(suppliedaxis,'Legend')
      suppliedaxis.Legend.FontSize     = legendfontsize;
      suppliedaxis.Legend.Location     = legendlocation;
      suppliedaxis.Legend.Interpreter  = legendinterpreter;

      hLegend  = suppliedaxis.Legend;

      numPlots    = numel(hLegend);
      for n = 1:numPlots  
         hLegend(n).ItemTokenSize = [18,18];  
         hLegend(n).LineWidth = 1;              % make the box thinner
      end
   end

   
% settings that cannot be adjusted axis-by-axis 

if setaxisonly == false
   
   %~~~~~~~~~~~~~~~~~~~~
   % LEGEND PROPERTIES
   %~~~~~~~~~~~~~~~~~~~~
   hLegend = findobj(gcf,'Type','Legend');
   set(hLegend,'FontSize',legendfontsize);
   set(hLegend,'Location',legendlocation);
   set(hLegend,'Interpreter',legendinterpreter);

   % both of these will thicken the lines in the plot AND legend
   % hLines = findobj(gca,'Type','line');
   % hLines = findall(gcf,'Type','line');
   % set(hLines,'LineWidth',3)

   % this will shorten the legend lines, but to thicken them the legend 
   % must be created with [hl,icons,plots,txt] = legend

   numPlots    = numel(hLegend);
   for n = 1:numPlots  
   hLegend(n).ItemTokenSize = [18,18];  
   hLegend(n).LineWidth = 1;              % make the box thinner
   end

   % this might work to run figformat after all subplots are finished
   % hAxes = findobj(gcf,'Type','Axes');

   %~~~~~~~~~~~~~~~~~~~~
   % LINE /PATCH OBJECTS 
   %~~~~~~~~~~~~~~~~~~~~
   if isempty(suppliedline)
   % apply formatting to all lines/patches
   hLines   = findobj(gcf,'Type','Line');
   hPatch   = findobj(gcf,'Type','Patch');

   set(hPatch,'LineWidth',patchlinewidth);
   set(hLines,'LineWidth',linelinewidth);
   else
   set(suppliedline,'LineWidth',linelinewidth);
   end

   %~~~~~~~~~~~~~~~~~~~~
   % TEXT OBJECTS
   %~~~~~~~~~~~~~~~~~~~~

   hText    = findobj(gcf,'Type','Text');
   set(hText,'Interpreter',textinterpreter);

   for n = 1:numel(hText)
   hText(n).FontSize = textfontsize;
   end

   % this was on the community forums but above seems to work 
   % set(findobj(allchild(gcf),'Type','AnnotationPane'),...
   % 'HandleVisibility','on')
   % findobj(gcf,'Type','textboxshape') 

   %~~~~~~~~~~~~~~~~~~~~
   % COLORBAR PROPERTIES
   %~~~~~~~~~~~~~~~~~~~~
   hCbar = findobj(gcf,'Type','Colorbar');
   %    set(hCbar,'FontSize',cbarfontsize);
   %    set(hCbar,'FontName',cbarfontname);
   %    set(hCbar,'FontWeight',cbarfontweight);
   %    set(hCbar,'Location',cbarlocation);
   %    set(hCbar,'Label',cbarlabel);
   %    set(hCbar,'Limits',cbarlimits);
   %    set(hCbar,'TickLabelInterpreter','cbarinterpreter');
   %    set(hCbar,'Interpreter',cbarinterpreter);
   %    
   
end

   % NOTE: if two figures are open and 'suppliedfigure' is not supplied,
   % this will copy the 'suppliedaxis' to gcf, which may not be the one you
   % want

   %~~~~~~~~~~~~~~~~~~~~
   % NEW AXIS
   %~~~~~~~~~~~~~~~~~~~~
   % add a solid box without tick marks around the right and upper
   
   % using copyobj solved the problem where I couldn't zoom afterward, b/c
   % with copyobj, I get the original plots on the new axis. I need to move
   % on, but might be better to remove the x/ylabels from ax1, because I
   % still cannot return control to ax1 without losing the ax2 box, so i
   % think subsequent efforts to modify the axes will not work
   
   % in some cases when plot is resized, the ticks and ticklabels will 
   % aren't linked (if i link them, then I can't have the second axis with
   % turned-off links
   
   suppliedaxis.Box = 'off';

% % alternative to just put a box around it, but then changing axis
% lims/dir etc. won't work, I think
%    xlims    = xlim;
%    ylims    = ylim;
%    xbox     = [xlims(1) xlims(2) xlims(2) xlims(1) xlims(1)];
%    ybox     = [ylims(1) ylims(1) ylims(2) ylims(2) ylims(1)];
%    
%    plot(xbox,ybox,'k','LineWidth',1);
   

   % this new method breaks stuff that used to work like when I call
   % figformat multiple times or on subplots, but don't have time to fix
   ax1 = suppliedaxis;
   
   % copyobj fails when figure has multiple coordinate systems 
   cantcopy = false;
   try 
      ax2 = copyobj(ax1,suppliedfigure); 
   catch ME
      
      if strcmp(ME.identifier,'MATLAB:Axes:UnsupportedCopy')
         cantcopy = true;
      end
   end
   
   % this doesn't work
   % ax2 = copyobj([ax1;hLegend],suppliedfigure); 
   
%    % this is how I did it in inset
%    mainFigAxes    =  findobj(mainHandle,'Type','axes');
%    mainLegend     =  findobj(mainHandle,'Type','Legend');
%    newMainAxes    =  copyobj([mainFigAxes; mainLegend],newFig);
   
   % i tried this to get the legend copied over. it might be useful, but it
   % doesn't solve that problem
   % copyobj(ax1.Children, ax2);
   
if cantcopy == true
   
   ax2 = ax1; % assign ax2 to ax1 (dummy)
   
else
   
   if iscategorical(ax1.XLim)
     
      % this is for the copyobj method
      set(ax2,'Position',get(ax1,'Position'),'Box','on','Color','none',...
             'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[],      ...
             'YLim',get(ax1,'YLim'),'XLabel',[],'YLabel',[]);
      set(gcf,'CurrentAxes',ax1);
      linkaxes([ax1 ax2],'xy');      % link axes in case of zooming
   else
                                                               pause(0.001)
      ax1pos  = plotboxpos(ax1);                               pause(0.001)
      ax1xlim = get(ax1,'XLim');
      ax1ylim = get(ax1,'YLim');
      
      % for tiledlayout, it seems like plotboxpos is returning the position
      % of the first tile, at least this is happening with bfra_checkevent

      % this is for the copyobj method
      set(ax2,'Position',ax1pos,'Box','on','Color','none',...
          'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[],      ...
          'YLim',ax1ylim,'XLabel',[],'YLabel',[]);
     %set(gcf,'CurrentAxes',ax1);
      
%       set(ancestor(ax1,'figure'),'CurrentAxes',ax1)
      
      % moved these here to deal with datetime error but iddn't work
      if ~isdatetime(ax1xlim)
         ax2.XLim = ax1xlim;
         linkaxes([ax2 ax1],'xy');
      end
      
      % had to add a longer pause for recurseive plotting but with new
      % copyobj functionality maybe it won't be needed
      pause(0.5); 

      % no longer needed with copyobj
      % axes(ax1) % set original axes as active
   end

   %set(gca,'XGrid','on','YGrid','on')
   pause(0.001); ax2.Position = plotboxpos(ax1); pause(0.001)

   % this is the magic that allows zooming/panning,
   % see:https://www.mathworks.com/matlabcentral/answers/710113-how-do-i-plot-2-images-each-with-a-different-colormap-and-clim-in-a-single-subplot#answer_592283
   % 
   
%    try
%       ax2.UserData = linkprop([ax1,ax2],...
%       {'Position','InnerPosition','ydir','xdir','xlim','ylim'}); % add more props as needed
% %       ax1.UserData = linkprop([ax1,ax2],...
% %       {'Position','InnerPosition','ydir','xdir','xlim','ylim'}); % add more props as needed
%    catch ME
%       
%       if strcmp(ME.msg,'')
%       end
%    end

	if istiled == false   
      ax2.UserData = linkprop([ax1,ax2],...
      {'Position','InnerPosition','ydir','xdir','xlim','ylim'}); % add more props as needed
      ax1.UserData = linkprop([ax1,ax2],...
      {'Position','InnerPosition','ydir','xdir','xlim','ylim'}); % add more props as needed
   else
      ax2.UserData = linkprop([ax1,ax2],...
      {'ydir','xdir','xlim','ylim'}); % add more props as needed
      ax1.UserData = linkprop([ax1,ax2],...
      {'ydir','xdir','xlim','ylim'}); % add more props as needed
   end
%    linkdata on
   % i commented this after improving formatPlotMarkers with inputparser,
   % which makes it easy enough to call outside this script
   % formatPlotMarkers
   
end

   h.figure            = gcf;
   h.mainAxis          = ax1;
   h.backgroundAxis    = ax2;
   h.legend            = hLegend;
   
   % this might fix the situation where I cannot add new plots on top of a
   % figformatted figure, but i am not sure of the implications for
   % subsequent calls to figformat wrt the copyobj stuff above. might need
   % to then move this type of statement to outside plot functions if/when
   % i need to add stuff to figformatted figures
   set(h.figure,'CurrentAxes',h.backgroundAxis);
   % set(ff.figure,'CurrentAxes',ff.backgroundAxis); % this would be added
   % to outsdide funcs
   
   
%    % could be useful, from comments on datetickzoom function, should allow
%    % panning/zooming of datetick axis
%    linkaxes(ax,'x') %link axis extents
%    addlistener(ax,'XLim','PostSet', ...
%       @(~,e)datetick(e.AffectedObject,'x','keeplimits')); %self updating time axis
   
end
   

function ff = refigformat(arg1,arg2)

   % parse input
   if isstruct(arg1)       % assume it's the figformat handle struct
     ff  = arg1;
     cmd = arg2;     
   elseif ischar(arg1)     % assume it's the command
     cmd = arg1;
     ff  = arg2;
   end

   switch cmd
     case {'align','realign','alignaxes'}
         ff.backgroundAxis.Position = plotboxpos(ff.mainAxis);
         ff.mainAxis.Position = plotboxpos(ff.backgroundAxis);


     case {'format','reformat'}

         ff = resetFormat(ff);

     case {'legendmarkeradjust','legendlines','formatlegend'}
         ff = reformatLegend(ff);

     case {'formatticks','tickformat','ticks','ticklabels'}
         ff = reformatTickLabels(ff);

   end

   % NOTE: in the case of multiple plots called in a row, if the axes git
   % misaligned, try this:
   % h1.backgroundAxis.Position = h1.mainAxis.Position;
   % h2.backgroundAxis.Position = h2.mainAxis.Position;

   end

   function ff = resetFormat(ff)

   set(findall(gcf,                                                ...
                 '-property','Interpreter'),                     ...
                 'Interpreter','latex');

   set(findall(gcf,                                                ...
                 '-property','TickLabelInterpreter'),            ...
                 'TickLabelInterpreter','latex');

   end


   function ff = reformatLegend(ff)


   %     hLegend = findobj(ff.figure, 'Type', 'Legend');
   %     hLegend.ItemTokenSize = [18,18];
   %     hLegend.LineWidth = 1;
   %     
   %     hLines = findobj(hlegend,'Type','line')

   end

   function ff = reformatTickLabels(ff)

   % not functional, just somewhere to start
   ff.mainAxis.XAxis.TickLabels = compose('%g',ff.mainAxis.XAxis.TickValues);
   ff.mainAxis.YAxis.TickLabels = round(ff.mainAxis.YAxis.TickValues-1,1);
   ff.backgroundAxis.Position   = ff.mainAxis.Position;
   end

   % this would work to modify all axes e..g in a subplot, but it messes with
   % the legend so I need to figure out how to add them back
   % axs = findobj(gcf,'Type','axes');
   % for n = 1:numel(axs)
   %     
   %     ax2 = axes('Position',get(axs(n),'Position'),'Box','on','Color','none',    ...
   %             'XTick',[],'XTickLabel',[],'YTick',[],'YTickLabel',[],      ...
   %             'XLim',get(axs(n),'XLim'),'YLim',get(axs(n),'YLim'));
   %     axes(axs(n)) % set original axes as active
   %     linkaxes([axs(n) ax2],'xy') % link axes in case of zooming
   %     box off 
   % end

   % keeping this for reference in case it's needed
   % colorbar('TickLabelInterpreter', 'latex')

   % I like lines at 1.5 but circles at 1, but this doesn't work
   % hlines = findobj(gca,'Type','line');
   % hmarks = findobj(gca,'Type','marker');
   % set(hlines,'LineWidth',1)
   % set(hmarks,'LineWidth',1)