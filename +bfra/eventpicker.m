function [T,Q,R,Info] = eventpicker(t,q,r,nmin,Info)
%EVENTPICKER automated or user-guided recession event selection 
% 
% Syntax
% 
%     [T,Q,R,Info] = eventpicker(t,q,r,nmin,Info)
% 
% Description
% 
%     [T,Q,R,Info] = eventpicker(t,q,r,nmin,Info) selects recession events from
%     input hydrograph with time 't', discharge 'q', and rain 'r'. Use optional
%     inputs to set parameters that determine how events are identified and   
% 
% Required inputs
% 
%     t        time
%     q        flow (m3/time)
%     r        rain (mm/time)
%     nmin     minimum event length
% 
% See also: getevents, findevents, eventfinder, eventsplitter, eventplotter
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% TODO: compare subfunction eventPlotter here to bfra.eventplotter and to
% versions in dev-bk. Cursory glance - eventPlotter includes option to plot
% rain, but does not include 3rd subplot of d2q/dt in bfra.eventplotter

%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'eventpicker';
p.StructExpand = false;             % for 'Info' input

addRequired(p, 't',     @(x) isnumeric(x) | isdatetime(x)         );
addRequired(p, 'q',     @(x) isnumeric(x) & numel(x)==numel(t)    );
addRequired(p, 'r',     @(x) isnumeric(x)                         );
addRequired(p, 'nmin',  @(x) isnumeric(x) & isscalar(x)           );
addRequired(p, 'Info',  @(x) isstruct(x)                          );

parse(p,t,q,r,nmin,Info);

%-------------------------------------------------------------------------------

% compute the first derivative
qdot = derivative(q);

% pick the events
Events = eventSelector(t,q,r,qdot,Info);
numEvents = numel(Events.inputTime);

% apply quality control filters to the picked events
Q = cell(numEvents,1);
T = cell(numEvents,1);
R = cell(numEvents,1);
Qdot = cell(numEvents,1);

% Note: this pulls T,Q,Q2 out of Events. Could change to send back Events
for n = 1:numEvents

   qPick = Events.Q{n};
   tPick = Events.T{n};
   rPick = Events.R{n};
   qdotPick = Events.Qdot{n};
   
   rl = Events.runlengths(n);
   
   % if the event is shorter than the min event criteria, skip it
   if rl<nmin; numEvents = numEvents-1; continue; end
   
   % islineconvex might be too restrictive, but without it, ETS call to
   % exponential fit sometimes fails, and nonlinear fitting will fail
   if islineconvex(qPick) || islineconvex(-diff(qPick))
      numEvents=numEvents-1;
      continue;
   end
   
   % otherwise, keep the pick
   Q{n} = qPick;
   T{n} = tPick;
   R{n} = rPick;
   Qdot{n} = qdotPick;

end

% remove empty events
inan = false(size(T));
for n = 1:numel(T)
   if isempty(T{n})
      inan(n) = true;
   end
end

T = T(~inan);
Q = Q(~inan);
R = R(~inan);
Qdot = Qdot(~inan);

% replace the start/stop/runlengths with the picked ones
Info.istart = Events.istart;
Info.istop = Events.istop;
Info.runlengths = Events.runlengths;
Info.hEvents = Events.h;

Info.istart = Info.istart(~inan);
Info.istop = Info.istop(~inan);
Info.runlengths = Info.runlengths(~inan);

% close all
% f = f(isgraphics(f)); close(f);

function Events = eventSelector(t,q,r,qdot,Info)

% convert t to datenum for easier arithmetic
t = datenum(t);

% pick the points
h = eventPlotter(t,q,r,qdot,Info);  % plot the timeseries

pickedPts = ginputc();
startPts = pickedPts(1:2:end);
endPts = pickedPts(2:2:end);
numPicks = numel(startPts);

% initialize output
istart      = nan(size(startPts));
istop       = nan(size(startPts));
rlength     = nan(size(startPts));
T           = cell(size(startPts));
Q           = cell(size(startPts));
R           = cell(size(startPts));
Qdot        = cell(size(startPts));

for n = 1:numPicks
   difStart    = abs(t-startPts(n));
   difStop     = abs(t-endPts(n));
   istart(n)   = findmin(difStart,1,'first');
   istop(n)    = findmin(difStop,1,'first');
   
   t_n         = t(istart(n):istop(n));
   q_n         = q(istart(n):istop(n));
   r_n         = r(istart(n):istop(n));
   qdot_n      = qdot(istart(n):istop(n));
   t_n         = t_n(qdot_n~=0);
   q_n         = q_n(qdot_n~=0);
   r_n         = r_n(qdot_n~=0);
   qdot_n      = qdot_n(qdot_n~=0);
   
   T{n}        = t_n;
   Q{n}        = q_n;
   R{n}        = r_n;
   Qdot{n}     = qdot_n;
   rlength(n)  = numel(q_n);
end

Events.T            = T;
Events.Q            = Q;
Events.R            = R;
Events.Qdot         = Qdot;
Events.nEvents      = numPicks;
Events.istart       = istart + Info.ifirst - 1;
Events.istop        = istop + Info.ifirst - 1;
Events.runlengths   = rlength;

% some of the information in Info is relevant to the entire timeseries:
% imaxima
% iminima
% iconvex
% icandidate
% ikeep
% ifirst

% some pertains to the automated selected events
% istart
% istop
% runlengths

% so we need to add a new field for picked events with:
% istart
% istop
% runlengths

% add the picked events to the plot
Events  = updateEventPlot(Events,h);


function h = eventPlotter(t,q,r,dqdt,Info)
   
% stripped down version of bfra.plotevents with ginput picking added

if isempty(Info.istart)
   disp('no valid events')
end

h.Info  = Info;
ifirst  = Info.ifirst(1);
ikeep   = Info.ikeep   - ifirst + 1;
imax    = Info.imaxima - ifirst + 1;
imin    = Info.iminima - ifirst + 1;
icon    = Info.iconvex - ifirst + 1;

posidx  = dqdt>=0;
negidx  = dqdt<0;
sz      = 20;

% new  - add 50th percentil
q50     =   quantile(q,0.5);

% make the figure
h.f     =   figure('Position',[1 1 1152 720]);
h.t1    =   subtight(2,1,1,'style','fitted');
h.ax1   =   gca;
h.s1a   =   scatter(t(posidx),q(posidx),sz,'filled'); hold on;
h.s1b   =   scatter(t(negidx),q(negidx),sz,'filled'); datetick;
h.s1c   =   scatter(t(imax),q(imax),sz*2,'filled');
h.s1d   =   scatter(t(imin),q(imin),sz*2,'filled');
h.s1e   =   scatter(t(icon),q(icon),sz,'filled');
h.s1f   =   scatter(t(ikeep),q(ikeep),sz*2.5,'filled');

h.s1g    =  hline(q50,':');

dates    =  datetime(t,'ConvertFrom','datenum');

title(year(dates(1)))
set(gca,'YScale','log');

h.l1 = legend('increasing','decreasing','maxima','minima','convex','keep','keep (check)');

ylabel('Q');

% add rain
if sum(r)>0
   ax       = gca;
   yyaxis right
   h.h1rain = bar(t,r,0.2,    'FaceColor',   [0.85 0.325 0.098],     ...
                              'FaceAlpha',   0.5,                    ...
                              'EdgeColor',   'none');

   ylabel('rain (mm)','Color',[0.85 0.325 0.098]);
   set(gca,'YColor','k')
   datetick; axis(ax,'ij');
end


% plot -dq/dt in log
dqdt     =  -dqdt;

h.t2     =   subtight(2,1,2,'style','fitted');
h.ax2    =   gca;
h.s2a    =   scatter(t(posidx),dqdt(posidx),sz,'filled'); hold on;
h.s2b    =   scatter(t(negidx),dqdt(negidx),sz,'filled');
h.s2c    =   scatter(t(imax),dqdt(imax),sz*2,'filled');
h.s2d    =   scatter(t(imin),dqdt(imin),sz*2,'filled');
h.s2e    =   scatter(t(icon),dqdt(icon),sz,'filled');
h.s2f    =   scatter(t(ikeep),dqdt(ikeep),sz*2.5,'filled');
h.hl2    =   hline(0,'k-'); h.hl2.LineWidth = 1;
h.l2     =   legend('increasing','decreasing','maxima','minima',     ...
               'convex','keep','AutoUpdate','off');
ylabel('dQ/dt');
datetick
set(gca,'YScale','log');

h.l1.Location = 'best';
h.l2.Location = 'best';

   % add rain
if sum(r)>0
   ax       = gca;
   yyaxis right
   h.h2rain = bar(t,r,0.2,    'FaceColor',   [0.85 0.325 0.098],     ...
                              'FaceAlpha',   0.5,                    ...
                              'EdgeColor',   'none');

   ylabel('rain (mm)','Color',[0.85 0.325 0.098]);
   set(gca,'YColor','k')
   datetick; axis(ax,'ij');
end


function Events = updateEventPlot(Events,h)
   
% add the picked events to the plot
for n = 1:Events.nEvents

   scatter(h.ax1,Events.T{n},Events.Q{n},60,'m');
   scatter(h.ax2,Events.T{n},Events.Qdot{n},60,'m');
   text(h.ax1,min(Events.T{n}),max(Events.Q{n}),['Event ' num2str(n)]);

   if n == 1
      h.l1.String{end}   = 'picked';
      h.l2.String{end+1} = 'picked';
   else
      h.l1.AutoUpdate    = 'off';
      h.l2.AutoUpdate    = 'off';
   end
end

Events.h = h;
