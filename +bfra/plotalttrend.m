function h = plotalttrend(t,Db,sigDb,varargin)
%PLOTALTTREND plot the active layer thickness trend
% 
% Syntax
% 
%     h = plotalttrend(t,Db,sigDb,varargin)
% 
% Description
% 
%     h = plotalttrend(t,Db,sigDb) plots annual values of active layer thickness
%     from baseflow recession analysis Db with errorbars representing estimation
%     uncertainty sigDb and the linear trendline. 
% 
%     h = plotalttrend(t,Db,sigDb,Dc,sigDc) also plots annual values of measured
%     active layer thickness Dc and measurement uncertainty sigDc.
% 
% See also prepalttrend

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
p              = magicParser;
p.FunctionName = 'bfra.plotalttrend';
p.addRequired( 't'                                                );
p.addRequired( 'Db'                                               );
p.addRequired( 'sigDb'                                            );
p.addOptional( 'Dc',       nan(size(Db)),    @(x) isnumeric(x)    );
p.addOptional( 'sigDc',    nan(size(Db)),    @(x) isnumeric(x)    );
p.addOptional( 'Dg',       nan(size(Db)),    @(x) isnumeric(x)    );
p.addParameter('ax',       gca,              @(x) isaxis(x)       );
p.addParameter('method',   'ols',            @(x)ischar(x)        );

p.parseMagically('caller');
%-------------------------------------------------------------------------------

if all(isnan(Dc)) && all(isnan(Dg))
   h = plotflowperiod(t,Db,sigDb,ax,method);
elseif all(isnan(Dg))
   h = plotcalmperiod(t,Db,sigDb,Dc,sigDc,ax,method);
else
   h = plotgraceperiod(t,Db,sigDb,Dc,sigDc,Dg,ax,method);
end

% if nargin > 5
%    Dc = varargin{1};
%    sigDc = varargin{2};
%    Dg = varargin{3};
%    if nargin >6
%       ax = varargin{2};
%    else
%       ax = nan;
%    end
%    h = plotgraceperiod(t,Db,sigDb,Dc,sigDc,Dg,ax);
% elseif nargin > 3
%    Dc = varargin{1};
%    sigDc = varargin{2};
%    h = plotcalmperiod(t,Db,sigDb,Dc,sigDc);
% else
%    h = plotflowperiod(t,Db,sigDb);
% end

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

function h = plotgraceperiod(t,Db,sigDb,Dc,sigDc,Dg,ax,method)

if all(isempty(Dg))
   h = nan;
   return
end

ctxt  = 'CALM (measured)';
btxt  = 'BFRA (theory: Eq. 21)';
gtxt  = 'GRACE $\\eta=S_G/\\phi$';

dc = defaultcolors;

% p1 plot needs 'reference',Dc where Dc is 1990-2020
% p1 plot needs 'reference',Db where Db is 1990-2020

if ~isa(ax,'matlab.graphics.axis.Axes')
   %f  = figure('Position',[289 149 668 476]); ax = gca;
   f  = figure('Units','centimeters','Position',[5 5 23 19*3/4]); ax = gca;
else
   f  = gcf;
end
   
p1 = trendplot(t,Dc,'units','cm a$^{-1}$','leg',ctxt,'use',ax,   ...
   'errorbounds',true,'errorbars',true,'yerr',sigDc,'reference',Dc, ...
   'method',method);
p2 = trendplot(t,Db,'units','cm a$^{-1}$','leg',btxt,'use',ax,   ...
   'errorbounds',true,'errorbars',true,'yerr',sigDb,'reference',Db, ...
   'method',method);
p3 = trendplot(t,Dg,'units','cm a$^{-1}$','leg',gtxt,'use',ax,   ...
   'errorbounds',true,'errorbars',true,'method',method);

set(ax,'XLim',[2001 2021],'YLim',[-80 80],'XTick',2002:3:2020);

p3.trend.Color          = dc(5,:);
p3.bounds.FaceColor     = dc(5,:);
p3.plot.MarkerFaceColor = dc(5,:);
p3.plot.Color           = dc(5,:);

p1.trend.LineWidth = 3;
p2.trend.LineWidth = 3;
p3.trend.LineWidth = 3;

ylabel('$ALT$ anomaly (cm)','Interpreter','latex');

grid off
% ff = figformat('suppliedfigure',f,'xgrid','off','ygrid','off');

str   = p1.ax.Legend.String;
str6  = strrep(str{1},'CALM (measured) (','');
str6  = ['2002:2020 ' strrep(str6,')','')];
str7  = strrep(str{2},[btxt ' ('],'');
str7  = ['2002:2020 ' strrep(str7,')','')];
str8  = strrep(str{3},[sprintf(gtxt) ' ('],'');
str8  = ['2002:2020 ' strrep(str8,')','')];

lobj  = [p1.plot p2.plot p3.plot p1.trend p2.trend p3.trend];
ltxt  = {ctxt; btxt; strrep(gtxt,'\\','\'); str6; str7; str8};
legend(lobj,ltxt,'numcolumns',2,'Interpreter','latex','location', ...
   'northwest','AutoUpdate','off');

p1.bounds.FaceAlpha = 0.15;
p2.bounds.FaceAlpha = 0.15;
p3.bounds.FaceAlpha = 0.05;


uistack(p1.trend,'top')
uistack(p2.trend,'top')
uistack(p3.trend,'top')

h.figure = f;
h.trendplot1 = p1;
h.trendplot2 = p2;
h.trendplot2 = p3;

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

function h = plotflowperiod(t,Db,sigDb,ax,method)

if all(isempty(Db))
   h = nan;
   return
end

btxt = 'BFRA (theory: Eq. 21)';

% this plots 1983-2020, no grace, no calm
% f     = figure('Position',[156    45   856   580]);
f = figure('Units','centimeters','Position',[5 5 23 19*3/4]);
p = trendplot(t,Db,'units','cm/yr','leg',btxt,'use',gca, ...
   'errorbounds',true,'errorbars',true,'yerr',sigDb, ...
         'method',method); 

% set transparency of the bars
set([p.plot.Bar, p.plot.Line], 'ColorType', 'truecoloralpha',   ...
   'ColorData', [p.plot.Line.ColorData(1:3); 255*0.5])

str   = p.ax.Legend.String;
str1  = strrep(str{1},[btxt ' ('],'');
str1  = strrep(str1,'cm/yr)','cm a$^{-1}$');

lobj  = [p.plot p.trend];
ltxt  = {btxt; str1};
legend(lobj,ltxt,'location','north','AutoUpdate','off');

% if I want to set the tick font to latext
% ax    = gca;
% ax.TickLabelInterpreter
ylabel('$ALT$ anomaly (cm)','Interpreter','latex');

p.trend.LineWidth = 2;

h.figure = f;
h.trendplot = p;

% xlims = xlim; ylims = ylim; box off; grid on;
% plot([xlims(2) xlims(2)],[ylims(1) ylims(2)],'k','LineWidth',1);
% plot([xlims(1) xlims(2)],[ylims(2) ylims(2)],'k','LineWidth',1);

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

function h = plotcalmperiod(t,Db,sigDb,Dc,sigDc,ax,method)

if all(isempty(Dc))
   h = nan;
   return
end

% load('defaultcolors','dc');
% ltext = [num2ltext('1990-2020 trend','',abC.Dc(2),'cm a$^{-1}$',2), ...
%          num2ltext('2002-2020 trend','',abG.Dc(2),'cm a$^{-1}$',2)];

ctxt  = 'CALM (measured)';
btxt  = 'BFRA (theory: Eq. 21)';
% btxt  = 'BFRA $\\eta=\\tau/[\\phi(N+1)]\\bar{Q}$';


% this plots 1990-2020, no grace
% f     = figure('Position',[156    45   856   580]);
f = figure('Units','centimeters','Position',[5 5 23 19*3/4]);
p1 = trendplot(t,Dc,'units','cm/yr','leg',ctxt,'use',gca, ...
   'errorbounds',true,'errorbars',true,'yerr',sigDc,'method',method);
p2 = trendplot(t,Db,'units','cm/yr','leg',btxt,'use',gca, ...
   'errorbounds',true,'errorbars',true,'yerr',sigDb,'method',method); 

% set transparency of the bars
set([p1.plot.Bar, p1.plot.Line], 'ColorType', 'truecoloralpha',   ...
            'ColorData', [p1.plot.Line.ColorData(1:3); 255*0.5])
set([p2.plot.Bar, p2.plot.Line], 'ColorType', 'truecoloralpha',   ...
            'ColorData', [p2.plot.Line.ColorData(1:3); 255*0.5])

% % set transparance of marker faces         
% set(p1.plot.MarkerHandle, 'FaceColorType', 'truecoloralpha',   ...
%             'FaceColorData', [p1.plot.Line.ColorData(1:3); 255*0.75])
% set(p2.plot.MarkerHandle, 'FaceColorType', 'truecoloralpha',   ...
%             'FaceColorData', [p2.plot.Line.ColorData(1:3); 255*0.75])      

str   = p1.ax.Legend.String;
str1  = strrep(str{1},'CALM (measured) (','');
str1  = strrep(str1,'cm/yr)','cm a$^{-1}$');
str2  = strrep(str{2},[btxt ' ('],'');
str2  = strrep(str2,'cm/yr)','cm a$^{-1}$');

lobj  = [p1.plot p2.plot p1.trend p2.trend];
ltxt  = {ctxt; btxt; str1; str2};
legend(lobj,ltxt,'location','north','AutoUpdate','off');

% if I want to set the tick font to latext
% ax    = gca;
% ax.TickLabelInterpreter
ylabel('$ALT$ anomaly (cm)','Interpreter','latex');

p1.trend.LineWidth = 2;
p2.trend.LineWidth = 2;

axis tight
set(gca,'XLim',[1990 2020],'XTick',1990:5:2020);

h.figure = f;
h.trendplot1 = p1;
h.trendplot2 = p2;

% xlims = xlim; ylims = ylim; box off; grid on;
% plot([xlims(2) xlims(2)],[ylims(1) ylims(2)],'k','LineWidth',1);
% plot([xlims(1) xlims(2)],[ylims(2) ylims(2)],'k','LineWidth',1);

% ff = figformat('legendlocation','north');
% ff.backgroundAxis.XLim = [1989 2021];
% ff.backgroundAxis.YLim = [-29 29];
% ylabel(ff.mainAxis,'$ALT$ anomaly (cm)');

% plot(x1,D1-mean(D1),'k','LineWidth',0.75,'HandleVisibility','off')
% plot(x1,D2-mean(D2),'k','LineWidth',0.75,'HandleVisibility','off')
% plot(x1,D1-mean(D1),'Color',dc(1,:),'LineWidth',0.75,'HandleVisibility','off')
% plot(x1,D2-mean(D2),'Color',dc(2,:),'LineWidth',0.75,'HandleVisibility','off')



% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% % this is the version that puts the grace period on the same figure. it almost
% % surely will not work out of the box, and I don't think we want it anyway
% 
% function plotbothperiods(t,D1,D2,sigD1,sigD2,D4,sigDg)
% 
% ctxt  = 'CALM (measured)';
% btxt  = 'BFRA (theory: Eq. 23)';
% gtxt  = 'GRACE $\\eta=S_G/\\phi$';
% 
% 
% f     = figure('Position',[156    45   856   580]);
% p1    = trendplot(t1,D1,'units','cm/yr','leg',ctxt,'use',gca,   ...
%          'errorbounds',false,'errorbars',true,'yerr',sigD1);
% p2    = trendplot(t1,D2,'units','cm/yr','leg',btxt,'use',gca,   ...
%          'errorbounds',false,'errorbars',true,'yerr',sigD2); 
% p3    = trendplot(t2,D3,'units','cm/yr','leg',ctxt,'use',gca,   ...
%          'errorbounds',true,'errorbars',true,'yerr',sigD3,'reference',D1);
% p4    = trendplot(t2,D4,'units','cm/yr','leg',btxt,'use',gca,   ...
%          'errorbounds',true,'errorbars',true,'yerr',sigD4,'reference',D2);
% p5    = trendplot(t2,D5,'units','cm a$^{-1}$','leg',gtxt,'use',gca,   ...
%          'errorbounds',true,'errorbars',true);
%       
% p3.bounds.FaceColor     = p1.plot.Color;
% p3.plot.Color           = p1.plot.Color;
% p3.plot.MarkerFaceColor = p1.plot.MarkerFaceColor;
% p3.trend.Color          = p1.trend.Color;
% p3.trend.LineStyle      = '--';
% p3.trend.LineWidth      = 2;
% 
% p4.bounds.FaceColor     = p2.plot.Color;
% p4.plot.Color           = p2.plot.Color;
% p4.plot.MarkerFaceColor = p2.plot.MarkerFaceColor;
% p4.trend.Color          = p2.trend.Color;
% p4.trend.LineStyle      = '--';
% p4.trend.LineWidth      = 2;
% 
% str   = p1.ax.Legend.String;
% str1  = strrep(str{1},'CALM (measured) (','');
% str1  = ['1990:2020 ' strrep(str1,'cm/yr)','cm/yr')];
% str2  = strrep(str{2},[btxt ' ('],'');
% str2  = ['1990:2020 ' strrep(str2,'cm/yr)','cm/yr')];
% str3  = strrep(str{3},'CALM (measured) (','');
% str3  = ['2002:2020 ' strrep(str3,'cm/yr)','cm/yr')];
% str4  = strrep(str{4},[btxt ' ('],'');
% str4  = ['2002:2020 ' strrep(str4,'cm/yr)','cm/yr')];
% str5  = strrep(str{5},[sprintf(gtxt) ' ('],'');
% str5  = ['2002:2020 ' strrep(str5,'cm/yr)','cm/yr')];
% 
% lobj  = [p1.plot p2.plot p5.plot p5.trend p1.trend p2.trend p3.trend p4.trend];
% ltxt  = {ctxt; btxt; strrep(gtxt,'\\','\'); str5; str1; str2; str3; str4};
% legend(lobj,ltxt,'numcolumns',2,'Interpreter','latex','location','northwest');
%    
% p3.bounds.FaceAlpha = 0.2;
% p3.bounds.FaceAlpha = 0.2;
% 
% set([p1.plot.Bar, p1.plot.Line], 'ColorType', 'truecoloralpha',   ...
%          'ColorData', [p1.plot.Line.ColorData(1:3); 255*0.5])
% set([p2.plot.Bar, p2.plot.Line], 'ColorType', 'truecoloralpha',   ...
%          'ColorData', [p2.plot.Line.ColorData(1:3); 255*0.5])
% 
% p1.trend.LineWidth = 1;
% p2.trend.LineWidth = 1;
% p3.trend.LineWidth = 3;
% p4.trend.LineWidth = 3;
% p5.trend.LineWidth = 3;
% p5.plot.MarkerSize = 8;
% 
% uistack(p3.trend,'top')
% uistack(p2.trend,'top')
% 
% set(gca,'YLim',[-80 65]);
% ylabel('$ALT$ anomaly (cm)','Interpreter','latex');
% 
% grid off
