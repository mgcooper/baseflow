function [h,f] = eventplotter(T,Q,R,Info,varargin)
   %EVENTPLOTTER plot recession events detected by eventfinder
   %
   % Syntax
   %
   %     h = eventplotter(t,q,r,Info)
   %     h = eventplotter(t,q,r,Info,eventTags)
   %     h = eventplotter(_,'dqdt',dQdt)
   %     h = eventplotter(_,'d2qdt',d2Qdt)
   %     h = eventplotter(_,'reversesign',true)
   %     h = eventplotter(_,'plotevents',false)
   %
   % Description
   %
   %     h = eventplotter(t,q,r,Info) Plots recession events identified by
   %     eventfinder on hydrograph t,q and rainfall r. Info is a structure
   %     returned by eventfinder that contains the indices of the start and end
   %     of each event as well as the local peaks, minimums, and runlength. An
   %     option to plot dq/dt as positive or negative values is available.
   %
   % Required inputs
   %
   %     T        time, numeric vector
   %     Q        flow, numeric vector (m3/time)
   %     R        rain, numeric vector (mm/time)
   %     Info     Info, structure returned by getevents.m
   %
   % Optional inputs
   % 
   %     eventTags   numeric vector, indices for events to plot 
   % 
   % Optional name-value inputs
   %
   %     dqdt: user-provided first derivative, default = backward finite diff
   %     d2qdt: user-provided second derivative, default = backward finite diff
   %     plotevents: logical, name-value e.g. 'plotevents',false to return
   %     without plotting (useful for calling from another function without
   %     needing to update the syntax)
   %     reversesign: logical, name-value indicating to plot dQ/dt instead of
   %     -dQ/dt on the y-axis.
   %     
   %
   % See also getevents, eventfinder, eventpicker, eventsplitter
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [T, Q, R, N, Info, eventTags, plotneg, plotevents, dqdt, d2qdt] = ...
      parseinputs(T, Q, R, Info, varargin{:});

   % short circuits
   if plotevents == false; h = []; return; end
   if isempty(Info.istart); disp('no valid events'); h = []; return; end

   % allow empty R i.e. input syntax eventplotter(T,Q,[],...)
   if isempty(R)
      R = zeros(size(T));
   end

   sz = 20; % this controls the size of the scatter symbols

   % Find increasing/decreasing values. Do this here so the indices are relative to
   % the same T,Q vectors as the Info indices.
   Info.ipositive = find(dqdt > 0);
   Info.inegative = find(dqdt < 0);

   % get the data for the requested events identified by their event tags
   if numel(eventTags) == N
      idx = 1:numel(T); % all events were requested
   else
      % create an index for the period of requested events padded by a week
      idx = Info.istart(min(eventTags)):1:Info.istop(max(eventTags));

      % this pads the indices by one week (or any other amount)
      idx = [idx(1)-10:1:idx(1)-1 idx idx(end)+1:1:idx(end)+10];

      % this uses all indices in the year(s) of this event(s)
      % idx = find(ismember(year(t),unique(year(t(idx)))));
   end

   fields = fieldnames(Info);
   for n = 1:numel(fields)
      thisfield = Info.(fields{n});
      keep = ismember(thisfield, idx);
      Info.(fields{n}) = thisfield(keep);
   end

   % convert the first and second derivatives to positive values
   if plotneg == true
      dqdt = -dqdt;
      d2qdt = -d2qdt;
   end

   % fields to plot
   % plotfields = {'ipositive','inegative','imaxima','iminima','iconvex','ikeep'};
   plotfields = {'icandidate','imaxima','iminima','iconvex','ikeep'};

   % make the figure
   % h.f = figure('Position',[1,1,1152*2/3,616*2/3]);
   f = figure('Units','inches','Position',[1,1,8.5,5],'Visible','on');

   % plot the panels
   for m = 1:3

      h.subplot(m) = subtight(3,1,m,'style','fitted');
      h.ax(m) = gca; hold on;

      % plot all values
      allidx = struct2vec(Info, plotfields);
      allidx = min(allidx):1:max(allidx);

      h1.alldata = scatter(h.ax(m), T(allidx), Q(allidx), 3*sz, ...
         [0.5 0.5 0.5], 'filled');

      for n = 1:numel(plotfields)

         thisfield = plotfields{n};
         ifield = Info.(thisfield);

         % increase the plot symbol size depending on the field
         switch thisfield
            case {'imaxima','iminima'}
               ssize = 2*sz;
            case 'ikeep'
               ssize = 2.5*sz;
            otherwise
               ssize = sz;
         end

         switch m
            case 1 % Q
               h1.(thisfield) = scatter(h.ax(m),T(ifield),Q(ifield),ssize,'filled');
            case 2 % dQ/dt
               h2.(thisfield) = scatter(h.ax(m),T(ifield),dqdt(ifield),ssize,'filled');
            case 3 % d2Q/dt2
               h3.(thisfield) = scatter(h.ax(m),T(ifield),d2qdt(ifield),ssize,'filled');
         end

      end

      % ltext = ['all data', strrepn(plotfields, 'i', '')];
      legend(['all data', plotfields], 'AutoUpdate', 'off', 'Orientation', ...
         'horizontal', 'Location', 'ne', 'FontSize', 10);
      set(gca,'FontSize',10)
   end

   % add labels
   if isoctave
      interpreter = 'tex';
   else
      interpreter = 'latex';
   end
   ylabel(h.ax(1), bfra.getstring('Q','units',true,'interpreter',interpreter), ...
      'Interpreter',interpreter,'FontSize',10);
   ylabel(h.ax(2),bfra.getstring('dQdt','units',true,'interpreter',interpreter), ...
      'Interpreter',interpreter,'FontSize',10);
   ylabel(h.ax(3),bfra.getstring('d2Qdt2','units',true,'interpreter',interpreter), ...
      'Interpreter',interpreter,'FontSize',10);

   % add a line at zero
   h2.zeroline = plot(h.ax(2),xlim(h.ax(2)),[0 0],'k-','LineWidth',1);
   h3.zeroline = plot(h.ax(3),xlim(h.ax(3)),[0 0],'k-','LineWidth',1);

   h.h1 = h1;
   h.h2 = h2;
   h.h3 = h3;

end

%% INPUT PARSER
function [T, Q, R, N, Info, eventTags, reversesign, plotevents, dqdt, d2qdt] = ...
      parseinputs(T, Q, R, Info, varargin)

   parser = inputParser;
   parser.FunctionName = 'bfra.eventplotter';

   N = numel(Info.istart);

   defaultdQdt = [0; diff(Q)]; % bfra.deps.derivative(Q);
   defaultd2Qdt = [0; diff(defaultdQdt)]; % bfra.deps.derivative(defaultdQdt);

   parser.addRequired('T', @isdatelike);
   parser.addRequired('Q', @isnumeric);
   parser.addRequired('R', @isnumeric);
   parser.addRequired('Info', @isstruct);
   parser.addOptional('eventTags', 1:N, @isnumericvector);
   parser.addParameter('reversesign', false, @islogicalscalar);
   parser.addParameter('plotevents', false, @islogicalscalar);
   parser.addParameter('dqdt', defaultdQdt, @isnumeric);
   parser.addParameter('d2qdt', defaultd2Qdt, @isnumeric);

   parser.parse(T, Q, R, Info, varargin{:});

   T = parser.Results.T;
   Q = parser.Results.Q;
   R = parser.Results.R;
   Info = parser.Results.Info;
   dqdt = parser.Results.dqdt;
   d2qdt = parser.Results.d2qdt;
   eventTags = parser.Results.eventTags;
   plotevents = parser.Results.plotevents;
   reversesign = parser.Results.reversesign;

   assert(numel(Q) == numel(T))
   assert(numel(dqdt) == numel(T))

   % Convert datetime to double if datetime was passed in
   T = todatenum(T);

end

% if ispublishing
%    exportgraphics(gcf,'html/event_example.png','Resolution',400);
% end

% snapnow

% % other options not in use
% %
% % plot the 50th percentile as a reference line
% % q50 = quantile(q,0.5);
% % h1.refline = bfra.deps.hline(h.ax(1),q50,':'); % add the 50th quantile line
%
%
% % plot the events identified by bfra.findevents, just to be sure
% %     for i = 1:length(T)
% %         h.s1g = scatter(T{i},Q{i},200,'r','LineWidth',2);
% %     end
% % h.l1 = legend('increasing','decreasing','maxima','minima','convex','keep','keep (check)');
%
% h.l1 = legend('increasing','decreasing','maxima','minima','convex','keep');
% ylabel(bfra.getstring('Q','units',true));
