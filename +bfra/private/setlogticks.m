function setlogticks(ax,varargin)
   %SETLOGTICKS set tick marks for log axis
   %
   %  setlogticks(ax,varargin)
   %
   % See also

   % --------------- parse inputs
   [ax, opts] = parseinputs(ax, mfilename, varargin{:});

   % --------------- get axis limits
   xlims = get(ax, 'XLim');
   ylims = get(ax, 'YLim');
   xticks = get(ax, 'XTick');
   yticks = get(ax, 'YTick');

   % get the number of decades spanned by each axis and ensure 2 ticks for one
   % decade or max 5 ticks for >5 decades
   if isnumeric(ylims)
      % Check for zeros. This may not work in general. Reset 0 to min value.
      if ismember(0, ylims)
         [~, ydata] = getplotdata(ax);
         ylims = sort([min(ydata)/1.05 ylims(~ismember(ylims, 0))]);
      end
      numdecy = log10(ylims(2))-log10(ylims(1));
      numticy = min(max(2,numdecy),5);
   end

   % repeat for xlims
   if isnumeric(xlims)
      % Check for zeros. This may not work in general. Reset 0 to min value.
      if ismember(0, xlims)
         xdata = getplotdata(ax);
         xlims = sort([min(xdata)/1.05 xlims(~ismember(xlims, 0))]);
      end
      numdecx = log10(xlims(2))-log10(xlims(1));
      numticx = min(max(2,numdecx),5); % no idea if 5 is generally good
   end


   % need to check if get(ax,'XTickMode) or get(ax,'XTickLabelMode) is manual
   skipx = false;
   skipy = false;
   if strcmp(get(ax, 'XTickMode'), 'manual') && ~strcmp('x', opts.axset)
      skipx = true;
   end
   if strcmp(get(ax,'YTickMode'),'manual') && ~strcmp('y', opts.axset)
      skipy = true;
   end

   % if the axes span <1 order of magnitude and there are already ticks, don't
   % replace them with the decades. If the axes are not numeric (e.g., if they are
   % categorical), don't adjust them.
   if isnumeric(xlims) && numdecx < 1; numticks = numel(get(ax,'XTick'));
      if numticks > 2; skipx = true; else, sub10x = true; end
   end

   if isnumeric(ylims) && numdecy < 1; numticks = numel(get(ax,'YTick'));
      if numticks > 2; skipy = true; else, sub10x = true; end
   end

   % This next block and the numdecx/y and numticx/y were added after the checks
   % above for isnumeric etc. and the xy if numel(xticks)<minxticks) check. Some
   % nomenclature can likely be combined/stnadardized and/or the two checks
   % may be redundant or negate each other

   % use numticx to determine the new ticks
   if isnumeric(xlims)
      xticmin = ceil(log10(min(xlims)));
      xticmax = fix(log10(max(xlims)));
      xticdec = max(1,fix((xticmax-xticmin)/numticx));
      xticks = 10.^(xticmin:xticdec:xticmax);
   else
      skipx = true;
   end

   if isnumeric(ylims)
      yticmin = ceil(log10(min(ylims)));
      yticmax = fix(log10(max(ylims)));
      yticdec = max(1,fix((yticmax-yticmin)/numticy));
      yticks = 10.^(yticmin:yticdec:yticmax);
   else
      skipy = true;
   end

   switch opts.axset
      case 'xy'

         if skipx == false

            if numel(xticks) < opts.minxticks

               % need to determine which new ticks to add, for now assume
               % we need to add one tick, covering the case where only one
               % is made at first and we want the default 2
               % numneeded = minxticks-numel(xticks);
               newticks = log10([xticks(1)/10 xticks(end)*10]);
               xlimslog = log10(xlims);
               tickdist = abs([newticks(1)-xlimslog(1), newticks(2)-xlimslog(2)]);
               itick1 = find(tickdist == min(tickdist), 1, 'first');
               xticks = sort([xticks, 10^newticks(itick1)]);
            end
            set(ax,'XTick',xticks);
         end

         if skipy == false
            set(ax,'YTick',yticks);
         end

      case 'x'

         if skipx == false
            set(ax,'XTick',xticks);
         end

      case 'y'

         if skipy == false
            set(ax,'YTick',yticks);
         end
   end
end

%% Input Parser
function [ax, opts] = parseinputs(ax, mfilename, varargin)
   parser = inputParser;
   parser.FunctionName = mfilename;
   parser.addRequired('ax', @isaxis);
   parser.addParameter('axset', 'xy', @ischar);
   parser.addParameter('minxticks', 2, @isnumeric);
   parser.addParameter('minyticks', 2, @isnumeric);
   parser.parse(ax, varargin{:});
   opts = parser.Results;
end