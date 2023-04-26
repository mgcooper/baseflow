function h = checkevent(T,Q,q,dqdt,r,alltags,eventtag,varargin)
%CHECKEVENT plot detected recession event and fitted values
%
% Syntax
% 
%     h = checkevent(T,Q,q,dqdt,r,alltags,eventtag)
% 
% Description
%  
%     h = checkevent(T,Q,q,dqdt,r,alltags,eventtag) makes a four-panel plot of
%     event identified by eventtag 
% 
% Required inputs
% 
%  q        approximated Q, e.g. Fits.q
%  dqdt     approximated dQ/dt, e.g. Fits.dqdt
%  tags     event tag array, e.g. Fits.tag
%  event    event tag (1:number of events, = max(tags))
%  T        time array, 1:number of time steps (not reshaped version)
%  Q        flow array, 1:number of time steps (not reshaped version)
% 
% 
% See also eventplotter
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% I think T,Q should be from Events, and q/dqdt/alltags/eventtag from Fits

% NOTE: two fits are shown in the legend b/c the first one is from the provided
% inputs and the second one is computed in this function as a check on the input

% --------------- parse inputs
p = bfra.deps.magicParser;
p.FunctionName = 'bfra.checkevent';

p.addRequired('T',               @(x)isnumeric(x) | isdatetime(x));
p.addRequired('Q',               @(x)isnumeric(x));
p.addRequired('q',               @(x)isnumeric(x));
p.addRequired('dqdt',            @(x)isnumeric(x));
p.addRequired('r',               @(x)isnumeric(x));
p.addRequired('alltags',         @(x)isnumeric(x));
p.addRequired('eventtag',        @(x)isnumeric(x));
p.addParameter('order',    nan,  @(x)isnumeric(x));
p.addParameter('ax',       gca,  @(x)bfra.validation.isaxis(x));

p.parseMagically('caller');

order = p.Results.order;

if isdatetime(T)
   T = datenum(T);
end

% --------------- function code
import bfra.util.subtight
warning off
colors = get(0,'defaultaxescolororder');
colors = colors([1 2 5 4 3 6 7],:); % swap yellow and green

% this allows a column vector of tags instead of a reshaped matrix
rowcol = true;
if all(size(Q) == size(T)) && all(size(Q) == size(alltags))
   rowcol = false;
end

if isnan(order); fixb = false; else, fixb = true; end


% --------------- prep for fitting

[  eventT,eventQ,                                                       ...
   eventq,eventdqdt,                                                    ...
   eventr,annualT,                                                      ...
   annualQ,annualr   ]  =  prepinput(rowcol,alltags,eventtag,T,Q,q,dqdt,r);


[  tfit,qfit,dqfit,                                                     ...
   Qtstr,aQbstr,                                                        ...
   qfit0,dqfit0,                                                        ...
   Qtstr0,aQbstr0,                                                      ...
   rsq0              ]  =  prepfits(eventq,eventdqdt,eventT,fixb,order);


% --------------- make the figure

h.f = figure('Position',[150 80 800 550]);
% h.f = gcf;

% plot the entire year and the event  (panel 1)
%h.t1  = tiledlayout(3,2,'TileSpacing','none','Padding','none');
%nexttile([1 2]);

% use subplot instead
h.t1 = subtight(3,2,[1 2],'style','fitted');

h.h1a = plot(annualT,annualQ, '-o','Color',colors(1,:) ); hold on;
h.h1b = plot(eventT,eventQ,   '-o','Color',colors(2,:) );
% h.h1c = plot(eventT,eventq,   '-o','Color',col(3,:) );

ylabel('$Q$ [m$^3$ d$^{-1}$]'); datetick(h.t1,'keepticks');

% these are temporary, new settings to get it to look right
box off; grid off
set(gca,'TickLength',[0.01 0.1],'YScale','log','TickLabelInterpreter','latex')

title([datestr(eventT(1)) ' - ' datestr(eventT(end)) ' (Event ' num2str(eventtag) ')']);

ax = gca;

% plot the rain as bars and add the legend
h.ax1a   = ax; clear ax
[hb,ax]  = plotrain(annualT,annualr); yyaxis left
h.h1d    = hb;
h.ax1b   = ax;
h.leg1   = legend('$Q$ (observed)','$Q$ (event)','rain','Interpreter','latex');
% h.leg1   = legend('$Q$ (observed)','$Q$ (event)','$Q$ (event fit)','rain');

% --------------- next subplot

% plot observed flow and fitted flow vs time (panel 2)
%nexttile(3);
h.t2 = subtight(3,2,3,'style','fitted');

h.h2a = plot(eventT,eventq,'-o', 'Color', colors(1,:) ); hold on;
h.h2b = plot(tfit,qfit,  ':',  'Color', colors(2,:),'LineWidth',3);

ylabel('$Q$ [m$^3$ d$^{-1}$]'); datetick;

set(gca,'TickLabelInterpreter','latex')

% plot fixed-b solution and update legend
if fixb == true
   h.h2c = plot(tfit,qfit0,':o','Color',colors(2,:));
   ltxt  = {'$Q$ (ETS fit)',Qtstr,Qtstr0,'rain'};
else
   ltxt  = {'$Q$ (ETS fit)',Qtstr,'rain'};
end

% plot the rain as bars and add the legend
h.ax2a   = gca;
[hb,ax]  = plotrain(eventT,eventr);
h.h2c    = hb;
h.ax2b   = ax;
h.leg2   = legend(ltxt,'Location','northeast','Interpreter','latex');

grid off

% --------------- next subplot

% plot observed dQdt and fitted dQdt vs Q  (panel 3)
% nexttile(5);
h.t3  = subtight(3,2,5,'style','fitted');

h.h3a = plot(eventT,-eventdqdt,'-o', 'Color',colors(1,:)); hold on;
h.h3b = plot(tfit,-dqfit,    ':',  'Color',colors(2,:),'LineWidth',3);

ylabel('-d$Q$/d$t$ [m$^3$ d$^{-1}$ d$^{-1}$]'); datetick;
set(gca,'TickLabelInterpreter','latex')

% plot fixed-b solution and update legend
if fixb == true
   h.h3c = plot(tfit,-dqfit0,':o','Color',colors(2,:));
   ltxt  = {'-d$Q$/d$t$ (ETS fit)',aQbstr,aQbstr0};
else
   ltxt  = {'-d$Q$/d$t$ (ETS fit)',aQbstr};
end

h.leg3   = legend(ltxt,'Interpreter','latex','location','northeast');
h.ax3    = gca;

grid off

% --------------- next subplot
% bfra_dQdt plot

%h.t4 = nexttile([2 1]);
h.t4 = subtight(3,2,[4 6],'style','fitted');

if all(isnan(eventq))
   return   
else
   h2 = bfra.pointcloudplot(eventq,eventdqdt,'ax',h.t4,'reflines', ...
      {'lowerenvelope','upperenvelope','early','late','bestfit'}, ...
      'reflabels',false,'rain',eventr,'addlegend',true);
   % h2  = bfra_plotdQdt(eventq,eventdqdt,'ax',ax,'rain',eventr); hold on;
   
   h.pcloud = h2;
   h.ax4    = gca;
   h.h4a    = h2.scatter;
   h.h4b    = h2.reflines; % h.h4b = h2.plots{:}; % if using bfra_plotdQdt
   
   
   if fixb
      plot(qfit0,-dqfit0,'--');
      ltxt = [aQbstr0 ' (r2 = ' printf(rsq0,2) ')'];
      h2.legend.String{end} = ltxt;
   end
   
   % settins
   
   set(h.h1a,'MarkerFaceColor',colors(1,:),'MarkerEdgeColor','none');
   set(h.h1b,'MarkerFaceColor',colors(2,:),'MarkerEdgeColor','none');
   % set(h.h1c,'MarkerFaceColor',col(3,:),'MarkerEdgeColor','none');
   set(h.h2a,'MarkerFaceColor',colors(1,:),'MarkerEdgeColor','none');
   set(h.h3a,'MarkerFaceColor',colors(1,:),'MarkerEdgeColor','none');
   
   % --------------- see all events for this year
   %bfra_plotevents(Tt,Qq,min(Qq)/200,6,1,'neg');
   
   %    h.ax2a.XLim = h.ax1a.XLim;
   
   % instead send the annual flow back to main and do it there
   h.T     = annualT;
   h.Q     = annualQ;
   
end


% --------------- prep input

function [eventT,eventQ,eventq,eventdq, ...
   eventr,annualT,annualQ,annualr] = prepinput(userc,tags,event,T,Q,q,dqdt,rain)

if userc == true
   [r,c] = find(tags==event);
else
   r  = find(tags==event);
   c  = 1;
end

% if 

eventT   = T(r);
eventQ   = Q(r,c(1));
eventq   = q(r,c(1));

eventdq  = dqdt(r,c(1));
eventr   = rain(r,c(1));

% pull out the time/flow for the entire year
if isdatetime(T); T = datenum(T); end

dates    = datevec(eventT);
eventyr  = dates(1,1);
dates    = datevec(T);
idx      = dates(:,1)==eventyr;
annualT  = T(idx);
annualQ  = Q(idx,c(1));
annualr  = rain(idx,c(1));


% --------------- prep fits

function [tfit,qfit,dqfit,Qtstr,aQbstr, ...
   qfit0,dqfit0,Qtstr0,aQbstr0,rsq0] = prepfits(eventq,eventdqdt,eventT,fixb,order);

% fit ab using nonlin
if all(isnan(eventq))
   qfit=nan;dqfit=nan;Qtstr='nan';aQbstr='nan';ab=nan;qfit0=nan;
   dqfit0=nan;Qtstr0='nan';aQbstr0='nan';rsq0=nan;
   return
end
Fit   = bfra.fitab(eventq,eventdqdt,'nls');
ab    = Fit.ab;
Q0    = eventq(find(~isnan(eventq),1,'first'));
tfit  = eventT(~isnan(eventq));

% predicted Q from non-lin free
[qfit,dqfit]   = bfra.Qnonlin(ab(1),ab(2),Q0,tfit-tfit(1));
[Qtstr,aQbstr] = bfra.QtauString(ab,'printvalues',true);

% if requested, fit with a fixed b value and get predicted Q and dQ/dt
if fixb == true
   Fit            = bfra.fitab(eventq,eventdqdt,'mean','order',order);
   ab0            = Fit.ab;
   rsq0           = Fit.rsq;
   [qfit0,dqfit0] = bfra.Qnonlin(ab0(1),ab0(2),Q0,tfit-tfit(1));
   [Qtstr0,aQbstr0]  = bfra.QtauString(ab0,'printvalues',true);
else
   ab0      = nan;
   rsq0     = nan;
   qfit0    = nan;
   dqfit0   = nan;
   Qtstr0   = nan;
   aQbstr0  = nan;
end

% --------------- plot rain

function [h,ax] = plotrain(time,rain)

rcolor = [0.85 0.325 0.098];

ax = gca; yyaxis right
h = bar(time,rain,0.2,  'FaceColor',   rcolor,           ...
                        'FaceAlpha',   0.5,              ...
                        'EdgeColor',   'none'            );

ylabel('rain (mm d$^{-1}$)','Color',rcolor);
set(gca,'YColor','k')
datetick; axis tight; axis(ax,'ij');


% --------------- extra stuff
% If I want to add back the log
%     yyaxis right
%     pause(0.001)
%     semilogy(t,q,'-o'); hold on; semilogy(t,qfit,':');
%     set(gca,'YScale','log')

%     yyaxis right
%     semilogy(t,-dqdt,'-o'); hold on; semilogy(t,dqfit,':'); datetick;
%     ylabel('-dQ/dt')


%     % for debugging
%     f       = @(a,b,Q0,x) (Q0^(1-b)-(1-b).*a.*x).^(1/(1-b));
%     qtst    = f(ab(1),ab(2),q(1),t-t(1)+1);
%     dqtst   = ab(1).*qtst.^ab(2);
%
%     figure; plot(t,q,'-o'); legend('obs'); datetick; hold on;
%     figure; plot(t,qfit,'-o'); legend('fit function'); datetick
%     figure; plot(t,qtst,'-o'); legend('fit test'); datetick
%
%     figure; plot(q,-dqdt,'-o');legend('obs');
%     figure; plot(qfit,dqfit,'-o'); legend('fit function');
%     figure; plot(q,-dqtst,'-o'); legend('fit test');

%abl         = bfra_quickfit(q,dqdt,'lin');
%[q,dqdt]    = bfra_Qlin(a,b,Q0,t)
