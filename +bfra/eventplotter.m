function h = eventplotter(t,q,r,Info,varargin)
%EVENTPLOTTER plots recession events detected by findevents, with options to
%plot dq/dt as positive or negative values
% 
% Required inputs:
%  t           =  time
%  q           =  flow (m3/time)
%  r           =  rain (mm/time)
%  Info        =  Info structure returned by findevents.m
% 
% Optional inputs:
% 
% dqdt:         user-provided dqdt, default = centered finite diff
% plotevents:   logical, name-value e.g. 'plotevents',true
% plotneg:      logical, name-value
% 
% %  See also: getevents, findevents, eventfinder, eventpicker, eventsplitter

%-------------------------------------------------------------------------------
% input handling
p              = inputParser;
p.FunctionName = 'eventplotter';

addRequired(p, 't',                    @(x) isnumeric(x) | isdatetime(x)      );
addRequired(p, 'q',                    @(x) isnumeric(x) & numel(x)==numel(t) );
addRequired(p, 'r',                    @(x) isnumeric(x)                      );
addRequired(p, 'Info',                 @(x) isstruct(x)                       );
addParameter(p,'plotneg',     false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'plotevents',  false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'dqdt',   derivative(q),@(x) isnumeric(x) & numel(x)==numel(t) );

parse(p,t,q,r,Info,varargin{:});

plotneg     = p.Results.plotneg;
plotevents  = p.Results.plotevents;
dqdt        = p.Results.dqdt;

%-------------------------------------------------------------------------------

% short circuits
    if plotevents == false; h = []; return; end
    if isempty(Info.istart); disp('no valid events'); h = []; return; end
%-------------------------------------------------------------------------------
    
    ikeep   = Info.ikeep;
    imax    = Info.imaxima;
    imin    = Info.iminima;
    icon    = Info.iconvex;
    
    h.Info  = Info;

    d2qdt   = derivative(dqdt);
    posidx  = dqdt>=0;
    negidx  = dqdt<0;
    sz      = 20;
     
    if plotneg == true
        dqdt    = -dqdt;
        d2qdt   = -d2qdt;
    end
    
    % new  - add 50th percentil
    q50     =   quantile(q,0.5);
    
    % make the figure
    h.f     =   macfig; 
%     h.t1    =   tiledlayout(3,1); 
%     h.ax1   =   nexttile;
    h.t1    =   subtight(3,1,1,'style','fitted'); 
    h.ax1   =   gca;
    h.s1a   =   scatter(t(posidx),q(posidx),sz,'filled'); hold on;
    h.s1b   =   scatter(t(negidx),q(negidx),sz,'filled'); datetick; 
    h.s1c   =   scatter(t(imax),q(imax),sz*2,'filled');
    h.s1d   =   scatter(t(imin),q(imin),sz*2,'filled');
    h.s1e   =   scatter(t(icon),q(icon),sz,'filled');
    h.s1f   =   scatter(t(ikeep),q(ikeep),sz*2.5,'filled');
    
    h.s1g   =   hline(q50,':');

    % plot the events identified by bfra.findevents, just to be sure
%     for i = 1:length(T)
%         h.s1g = scatter(T{i},Q{i},200,'r','LineWidth',2);
%     end
    
    h.l1    =   legend('increasing','decreasing','maxima','minima',     ...
                    'convex','keep','keep (check)');
                ylabel('Q'); 
   %figformat;
    
                
    h.t2    =   subtight(3,1,2,'style','fitted'); 
    h.ax2   =   gca;
    h.s2a   =   scatter(t(posidx),dqdt(posidx),sz,'filled'); hold on;
    h.s2b   =   scatter(t(negidx),dqdt(negidx),sz,'filled');
    h.s2c   =   scatter(t(imax),dqdt(imax),sz*2,'filled');
    h.s2d   =   scatter(t(imin),dqdt(imin),sz*2,'filled');
    h.s2e   =   scatter(t(icon),dqdt(icon),sz,'filled');
    h.s2f   =   scatter(t(ikeep),dqdt(ikeep),sz*2.5,'filled');
    h.hl2   =   hline(0,'k-'); h.hl2.LineWidth = 1; 
    h.l2    =   legend('increasing','decreasing','maxima','minima',     ...
                    'convex','keep','AutoUpdate','off');

    if plotneg == true
        ylabel('-dQ/dt'); 
    else
        ylabel('dQ/dt'); 
    end
    datetick;
   %figformat;
    
%     h.ax3   =   nexttile; 
    h.t3    =   subtight(3,1,3,'style','fitted'); 
    h.ax3   =   gca;
    h.s3a   =   scatter(t(posidx),d2qdt(posidx),sz,'filled'); hold on;
    h.s3b   =   scatter(t(negidx),d2qdt(negidx),sz,'filled');
    h.s3c   =   scatter(t(imax),d2qdt(imax),sz*2,'filled');
    h.s3d   =   scatter(t(imin),d2qdt(imin),sz*2,'filled');
    h.s3e   =   scatter(t(icon),d2qdt(icon),sz,'filled');
    h.s3f   =   scatter(t(ikeep),d2qdt(ikeep),sz*2.5,'filled');
    h.hl3   =   hline(0,'k-'); h.hl3.LineWidth = 1;     
    h.l3    =   legend('increasing','decreasing','maxima','minima',     ...
                    'convex','keep','AutoUpdate','off');
 
    if plotneg == true
        ylabel('$-\mathrm{d}^2Q/\mathrm{d}t^2$','Interpreter','latex'); 
    else
        ylabel('$\mathrm{d}^2Q/\mathrm{d}t^2$','Interpreter','latex'); 
    end
    datetick
                
    h.l1.Location   = 'best';
    h.l2.Location   = 'best';
    h.l3.Location   = 'best';
    

end
