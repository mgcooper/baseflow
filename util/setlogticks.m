function setlogticks(ax,varargin)
   
   p=MipInputParser;
   p.FunctionName='setlogticks';
   p.addRequired('ax',@(x)isaxis(x));
   p.addParameter('axset','xy',@(x)ischar(x));
   p.addParameter('minxticks',2,@(x)isnumeric(x)); % minimum # of ticks
   p.addParameter('minyticks',2,@(x)isnumeric(x)); % minimum # of ticks
   p.parseMagically('caller');
   
   xlims    = ax.XLim;
   ylims    = ax.YLim;
   xticks   = ax.XTick;
   yticks   = ax.YTick;
   
   % get the number of decades spanned by each axis
   numdecy  = log10(ylims(2))-log10(ylims(1));
   numdecx  = log10(xlims(2))-log10(xlims(1));
   
   % ensure 2 ticks for one decade or max 5 ticks for >5 decades
   numticx  = min(max(2,numdecx),5); % no idea if 5 is generally good
   numticy  = min(max(2,numdecy),5);
   
   % need to check if ax.XTickMode or ax.XTickLabelMode is manual
   skipx = false;
   skipy = false;
   if strcmp(ax.XTickMode,'manual'); skipx = true; end
   if strcmp(ax.YTickMode,'manual'); skipy = true; end
      
   
   % if the axes only span <1 order of magnitude and there are already
   % ticks, don't replace them with the decades
   if numdecx < 1; numticks = ax.XTick;
      if numticks > 2; skipx = true; else, sub10x = true; end
   end
   
   if numdecy < 1; numticks = ax.YTick;
      if numticks > 2; skipy = true; else, sub10x = true; end
   end
   
   % this and the numdecx/y and numticx/y were added after the stuff right
   % above and the stuff in xy if numel(xticks)<minxticks), not sure if
   % some nomenclature can be combined/stnadardized and/or how the two
   % checks complement or negate each other
   % use numticx to determine the new ticks
   xticmin  = ceil(log10(min(xlims)));
   xticmax  = fix(log10(max(xlims)));
   xticdec  = max(1,fix((xticmax-xticmin)/numticx));
   xticks   = 10.^(xticmin:xticdec:xticmax);
      
   yticmin  = ceil(log10(min(ylims)));
   yticmax  = fix(log10(max(ylims)));
   yticdec  = max(1,fix((yticmax-yticmin)/numticy));
   yticks   = 10.^(yticmin:yticdec:yticmax);
            
   switch axset
      case 'xy'
         
         if skipx == false
            
            if numel(xticks)<minxticks
               
               % need to determine which new ticks to add, for now assume
               % we need to add one tick, covering the case where only one
               % is made at first and we want the default 2
               % numneeded = minxticks-numel(xticks);
               newticks    = log10([xticks(1)/10 xticks(end)*10]);
               xlimslog    = log10(xlims);
               tickdist    = abs([newticks(1)-xlimslog(1),...
                                 newticks(2)-xlimslog(2)]);
               itick       = findmin(tickdist,1,'first');
               xticks      = sort([xticks,10^newticks(itick)]);
            end
            
            ax.XTick = xticks;
            
         end
         
         if skipy == false
            
            ax.YTick = yticks;
         end
         
      case 'x'
         
         if skipx == false
            ax.XTick = xticks;
         end
         
      case 'y'
         
         if skipy == false
            ax.YTick = yticks;
         end
         
   end
      
end
   
   
      
   