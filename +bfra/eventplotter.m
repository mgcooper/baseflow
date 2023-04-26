function [h,f] = eventplotter(T,Q,R,Info,varargin)
%EVENTPLOTTER plot recession events detected by eventfinder
%
% Syntax
%
%     h = eventplotter(t,q,r,Info,varargin)
%
% Description
%
%     h = eventplotter(t,q,r,Info) Plots recession events identified by
%     eventfinder on hydrograph t,q and rainfall r. Info is a structure returned
%     by eventfinder that contains the indices of the start and end of each
%     event as well as the local peaks, minimums, and runlength. An option to
%     plot dq/dt as positive or negative values is available.
%
% Required inputs
%
%     T        time
%     Q        flow (m3/time)
%     R        rain (mm/time)
%     Info     Info structure returned by findevents.m
%
% Optional name-value inputs
%
%  dqdt: user-provided dqdt, default = centered finite diff
%  plotevents: logical, name-value e.g. 'plotevents',true
%  plotneg: logical, name-value
%
% See also getevents, eventfinder, eventpicker, eventsplitter
%
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
% input handling
p              = inputParser;
p.FunctionName = 'eventplotter';

N = numel(Info.istart);

addRequired(p, 'T',                    @(x) bfra.validation.isdatelike(x));
addRequired(p, 'Q',                    @(x) isnumeric(x) & numel(x)==numel(T));
addRequired(p, 'R',                    @(x) isnumeric(x));
addRequired(p, 'Info',                 @(x) isstruct(x));
addOptional(p, 'eventTags',   1:N,     @(x) bfra.validation.isnumericvector(x));
addParameter(p,'plotneg',     false,   @(x) bfra.validation.islogicalscalar(x));
addParameter(p,'plotevents',  false,   @(x) bfra.validation.islogicalscalar(x));
addParameter(p,'dqdt', bfra.deps.derivative(Q),@(x) isnumeric(x) & numel(x)==numel(T) );

parse(p,T,Q,R,Info,varargin{:});

eventTags   = p.Results.eventTags;
plotneg     = p.Results.plotneg;
plotevents  = p.Results.plotevents;
dqdt        = p.Results.dqdt;
%-------------------------------------------------------------------------------

% short circuits
if plotevents == false; h = []; return; end
if isempty(Info.istart); disp('no valid events'); h = []; return; end

% otherwise, prep the data to plot
import bfra.util.subtight

% allow empty R i.e. input syntax eventplotter(T,Q,[],...)
if isempty(R)
   R = zeros(size(T));
end

sz = 20; % this controls the size of the scatter symbols

% compute the second derivative and the increasing/decreasing values. do this
% here so the indices are relative to the same T,Q vectors as the Info indices
d2qdt = bfra.deps.derivative(dqdt);
Info.ipositive = find(dqdt>=0);
Info.inegative = find(dqdt<0);

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
   keep = ismember(thisfield,idx);
   Info.(fields{n}) = thisfield(keep);
end

% convert the first and second derivatives to positive values
if plotneg == true
   dqdt = -dqdt;
   d2qdt = -d2qdt;
end

% fields to plot
plotfields = {'ipositive','inegative','imaxima','iminima','iconvex','ikeep'};

% turned this off so h is a gobjects array
% h.Info = Info;

% make the figure
% h.f = figure('Position',[1,1,1152*2/3,616*2/3]);
f = figure('Units','inches','Position',[1,1,8.5,5],'Visible','on');
% tiledlayout(3,1,'TileSpacing','tight','Padding','tight'); 

% plot the panels
for m = 1:3

%    nexttile;
   h.subplot(m) = subtight(3,1,m,'style','fitted');
   h.ax(m) = gca; hold on;

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

   legend('increasing','decreasing','maxima','minima','convex','keep', ...
      'AutoUpdate','off','Orientation','horizontal','Location','ne',...
      'FontSize',10);
   
   set(gca,'FontSize',10)
end

% add labels
ylabel(h.ax(1),bfra.getstring('Q','units',true),'FontSize',10);
ylabel(h.ax(2),bfra.getstring('dQdt','units',true),'FontSize',10);
ylabel(h.ax(3),bfra.getstring('d2Qdt2','units',true),'FontSize',10);

% add a line at zero
h2.zeroline = plot(h.ax(2),xlim(h.ax(2)),[0 0],'k-','LineWidth',1);
h3.zeroline = plot(h.ax(3),xlim(h.ax(3)),[0 0],'k-','LineWidth',1);

h.h1 = h1;
h.h2 = h2;
h.h3 = h3;

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
