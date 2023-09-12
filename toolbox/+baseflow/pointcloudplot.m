function out = pointcloudplot(q,dqdt,varargin)
   %POINTCLOUDPLOT Plot a point-cloud diagram to estimate aquifer parameters.
   %
   % Syntax
   %
   %     out = pointcloudplot(q,dqdt,varargin)
   %
   % Required inputs
   %
   %     q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
   %     dqdt        =  discharge rate of change (L T^-2)
   %
   % Optional name-value inputs
   %
   %     mask        =  vector logical mask to exclude values from fitting
   %     reflines    =  cell array of chars indicating what type of reflines to plot
   %     reflabels   =  logical indicating whether to add labels
   %     blate       =  late-time b parameter in -dqdt = aq^b (dimensionless)
   %     userab      =  2x1 double indicating a user-defined intercept,slope pair
   %     precision   =  scalar double indicating the precision in the x data, used to
   %                    compute the 'lower envelope'
   %     timestep    =  scalar double indicating the timestep of the x data, used to
   %                    compute the 'lower envelope'
   %     addlegend   =  logical indicating whether to add a legend or not
   %     usertext    =  char that gets added to the legend if refline 'userfit' (to
   %                    indicate what is being plotted, maybe a custom user model)
   %     rain        =  vector double of rainfall (mm/time)
   %     ax          =  graphic axis to plot into
   %
   % See also: fitab, plotdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % Note: ab is for 'reflines','userfit' so a pre-computed ab can be plotted

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [q, dqdt, mask, reflines, reflabels, blate, userab, precision, timestep, ...
      addlegend, usertext, rain, ax] = parseinputs(q, dqdt, varargin{:});

   % create the figure / axes
   if not(isaxis(ax)) || isempty(ax)
      figure;
      ax = gca;
   end
   fig = get(ax,'Parent');
   set(fig, 'Position',[0 0 550 510]);

   % plot the data
   h0 = loglog(ax,q,-dqdt,'o');
   formatPlotMarkers('markersize',6);
   hold on; grid off;

   % add circles around the t>tau0 values if requested
   if sum(mask) < numel(q)
      h1 = scatter(q(mask),-dqdt(mask),'r');
   else
      h1 = [];
   end

   % add some space around the data
   xlims = xlim;
   ylims = ylim;
   ylowlim = min(ylims);
   yupplim = max(ylims);

   xlim([xlims(1)*.9 xlims(2)*1.1]);
   % xlim([xlims(1)/(log10(xlims(2))-log10(xlims(1))) *.09 xlims(2)*1.1]);

   % set xylabels and init containers for reflines
   if isoctave
      xlabel('Q (m^3 d^{-1})','FontSize',14, 'Interpreter', 'tex');
      ylabel('-dQ/dt (m^3 d^{-2})','FontSize',14, 'Interpreter', 'tex');

      h = zeros(numel(reflines),1);
   else
      xlabel(baseflow.getstring('Q','units',true),'FontSize', 14, 'Interpreter', 'latex');
      ylabel(baseflow.getstring('dQdt','units',true),'FontSize',14, 'Interpreter', 'latex');

      h = gobjects(numel(reflines),1);
   end

   % initialize array to hold parameters a and b
   ab = nan(numel(reflines),2);

   % add reference lines
   for n = 1:numel(reflines)
      
      switch reflines{n}
         case 'early'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','earlytime',        ...
                              'refslope',3,                 ...
                              'labels',reflabels,           ...
                              'mask',mask                   ...
                              );
            set(h(n),'LineWidth',1);
            
         case 'late'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','latetime',         ...
                              'refslope',blate,             ...
                              'labels',reflabels,           ...
                              'mask',mask                   ...
                              );
            set(h(n),'LineWidth',1);
            
         case 'upperenvelope'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','upperenvelope',    ...
                              'labels',reflabels            ...
                              );
            % make ylimits span the min dq/dt to the upper envelope at max Q
            yupplim = ab(n,1)*max(xlims)^ab(n,2);
            
         case 'lowerenvelope'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','lowerenvelope',    ...
                              'labels',reflabels            ...
                              );
            ylowlim = min(0.8.*ab(n,1),0.8*min(ylims));
            
         case 'bestfit'
            [h(n),ab(n,:)] = baseflow.plotrefline(              ...
                              q,-dqdt,                      ...
                              'refline','bestfit',          ...
                              'labels',false                ...
                              );
            set(h(n),'LineWidth',2);
            
         case 'userfit'
            [h(n),ab(n,:)] =  baseflow.plotrefline(             ...
                              q,-dqdt,                      ...
                              'refline','userfit',          ...
                              'userab',userab,              ...
                              'labels',reflabels,           ...
                              'mask',mask                   ...
                              );
      end
      out.ab.(reflines{n}) = ab(n,:);
   end
   set(gca,'YLim',[ylowlim yupplim]);

   % plot rain if provided
   if all(~isnan(rain))
      hrain = plotrain(ax,h0,rain,q,-dqdt);
   else
      hrain = nan;
   end

   % leaving this out for now
   if addlegend == true

      % check if both userfit and bestfit are requested
      fitcheck = {'bestfit','userfit'};

      if all(ismember(fitcheck,reflines))

         % ------------------------------------
         %          % put them both in the legend
         %          ibf   = ismember(reflines,fitcheck);
         %          hleg  = h(ibf);
         %
         %          ibest = strcmp(reflines,'bestfit');
         %          iuser = strcmp(reflines,'userfit');
         %          tbest = [baseflow.aQbString(ab(ibest,:),'printvalues',true) ' (NLS fit)'];
         %          tuser = [baseflow.aQbString(ab(iuser,:),'printvalues',true) ' (user fit)'];
         %
         %          % if user text provided, swap it out
         %          if ~isempty(usertext)
         %             tuser = [baseflow.aQbString(ab(iuser,:),'printvalues',true) ' (' usertext ')'];
         %          end
         %          ltext = {tbest; tuser};
         % ------------------------------------

         % only put bestfit in the legend
         keep = strcmp(reflines,'bestfit');
         hleg = h(keep);
         ltxt = baseflow.aQbString(ab(keep,:),'printvalues',true);
         ltxt = [ltxt ' (' upper(usertext) ' fit)'];
         %ltxt = [ltxt ' (nonlinear least-squares)'];

         % check if either userfit or bestfit are requested
      elseif any(ismember(fitcheck,reflines))

         % use whichever one was requested
         keep = ismember(reflines,fitcheck);
         hleg = h(keep);
         ltxt = baseflow.aQbString(ab(keep,:),'printvalues',true);

         if ~isempty(usertext)
            ltxt = [ltxt ' (' upper(usertext) ' fit)'];
         elseif ~any(ismember(reflines,'userfit'))
            ltxt = [ltxt ' (NLS fit)'];
         elseif ~any(ismember(reflines,'bestfit'))
            ltxt = [ltxt ' (MLE fit)'];
         end

      end

      if isobject(hrain)
         hleg = [hleg hrain];
         ltxt = {ltxt,'rain'};
      end

      ltxt = strrep(ltxt,'$','');
      l = legend(hleg,ltxt,'location','northwest','interpreter','tex', ...
         'AutoUpdate','off');

      %    if isoctave
      %       ltxt = strrep(ltxt,'$','');
      %       l = legend(hleg,ltxt,'location','northwest','interpreter','tex', ...
      %          'AutoUpdate','off');
      %    else
      %       l = legend(hleg,ltxt,'location','northwest','interpreter','latex', ...
      %          'AutoUpdate','off');
      %    end

   else
      l = nan;
   end
   % package the output
   out.fig        = fig;
   out.scatter    = h0;
   out.mask       = h1;
   out.reflines   = h;
   out.ax         = gca;
   out.hrain      = hrain;
   out.legend     = l;
end

%% LOCAL FUNCTIONS
function hrain = plotrain(ax,h,rain,x,y)

   % ax is the axis to plot into
   % h is the handle of the plotted q/dqdt to get the marker size to scale
   % the rain circles
   % x and y are q -dqdt

   % add rain. scale the circles such that 1 mm of rain equals the size of
   % the plotted circles
   if sum(rain)==0
      hrain = nan;
   else

      % scatter is producing pixelated symbols so I use plot instead
      % sz = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
      % scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)

      % this mimics the way scatter scales the circles
      sz = get(h,'MarkerSize') + sqrt(pi.*(rain(rain>0)).^2);
      x = x(rain>0);
      y = y(rain>0);

      hold on;
      for n = 1:numel(sz)
         hrain(n) = plot(ax,x(n),y(n),'o','MarkerSize',sz(n), ...
            'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
end

%% INPUT PARSER
function [q, dqdt, mask, reflines, reflabels, blate, userab, precision, ...
      timestep, addlegend, usertext, rain, ax] = parseinputs(q, dqdt, varargin)
   
   parser = inputParser;
   parser.addRequired('q', @isnumeric);
   parser.addRequired('dqdt', @isnumeric);
   parser.addParameter('mask', true(size(q)), @islogical);
   parser.addParameter('reflines', {'bestfit'}, @iscell);
   parser.addParameter('reflabels', false, @islogical);
   parser.addParameter('blate', 1, @isnumeric);
   parser.addParameter('userab', [1 1], @isnumeric);
   parser.addParameter('precision', 1, @isnumeric);
   parser.addParameter('timestep', 1, @isnumeric);
   parser.addParameter('addlegend', true, @islogical);
   parser.addParameter('usertext', '', @ischar);
   parser.addParameter('rain', nan, @isnumeric);
   parser.addParameter('ax', emptyaxes(), @isaxis);
   parser.FunctionName = 'baseflow.pointcloudplot';
   
   parser.parse(q, dqdt, varargin{:});

   mask = parser.Results.mask;
   reflines = parser.Results.reflines;
   reflabels = parser.Results.reflabels;
   blate = parser.Results.blate;
   userab = parser.Results.userab;
   precision = parser.Results.precision;
   timestep = parser.Results.timestep;
   addlegend = parser.Results.addlegend;
   usertext = parser.Results.usertext;
   rain = parser.Results.rain;
   ax = parser.Results.ax;
end
