function H = hyetograph(time,flow,prec,varargin)
%HYETOGRAPH Plot a discharge rainfall hyetograph
%
%  H = hyetograph(time,flow,ppt) plots hyetograph using data in flow and ppt
%
%  H = hyetograph(time,flow,ppt,t1,t2) plots hyetograph using data in flow and
%  ppt for time period bounded by datetimes t1 and t2
%
% Example, how to later access the plot objects
%  H = hyetograph(...);
%
% Find specific handles using 'Tag' or 'Name'
%
% fig = findobj(H, 'Name', 'Hyetograph');
% ax_streamflow = findobj(H, 'Tag', 'StreamflowAxis');
% ax_precipitation = findobj(H, 'Tag', 'PrecipitationAxis');
%
% See also

% --------------- parse inputs
p = bfra.deps.magicParser; %#ok<*NODEF,*USENS>
p.FunctionName = mfilename;
p.addRequired('time', @(x)bfra.validation.isdatelike(x));
p.addRequired('flow', @(x)bfra.validation.isnumericvector(x));
p.addRequired('prec', @(x)bfra.validation.isnumericvector(x));
p.addOptional('t1', min(time), @(x)bfra.validation.isdatelike(x));
p.addOptional('t2', max(time), @(x)bfra.validation.isdatelike(x));
p.addParameter('units', {'mm','cm d-1'}, @(x)bfra.validation.ischarlike(x));
% p.addParameter('ax', gca, @(x)bfra.validation.isaxis(x)  );
p.parseMagically('caller');

% --------------- function code

% initialize container for output handles
H = gobjects(4,1); % figure, ax1, plot1, plot2

% % get the figure handle
fig = gcf;
fig.Name = 'Hyetograph';
fig.Tag = 'HyetographFigure';
% fig.Position = [10,10,400,300];
% fig.Renderer = 'painters';

% k = fig.Parent;
% k.Parent.Position = [360 198 400 300];

% convert to columns
time = time(:);
prec = prec(:);
flow = flow(:);

% convert to datetime
if ~isdatetime(time); time = datetime(time,'ConvertFrom','datenum'); end
if ~isdatetime(t1); t1 = datetime(t1,'ConvertFrom','datenum'); end
if ~isdatetime(t2); t2 = datetime(t2,'ConvertFrom','datenum'); end

% trim to t1,t2 timespan
prec = prec(isbetween(time,t1,t2));
flow = flow(isbetween(time,t1,t2));
time = time(isbetween(time,t1,t2));

% process units
units = bfra.util.siUnitsToTex(units);

% get default colors
colors = get(0,'defaultaxescolororder');

% Create plot
yyaxis left;
h1 = plot(time,flow,'-o','MarkerSize',4,'MarkerFaceColor',colors(1,:), ...
   'MarkerEdgeColor','none','Tag','StreamflowPlot');
ax = gca;
ax.Tag = 'HyetographAxis';

% % With yyaxis, there is only one axis, so I don't track them separately
% ax1 = gca;
% ax1.Tag = 'StreamflowAxis';

% Set the remaining axes properties
set(ax,'XMinorGrid','on','YMinorGrid','on');
grid(ax,'on');

% hacky way to make space so the precip bars do not obscure the streamflow
% ylim([ax.YLim(1),1.5*ax.YLim(2)]);

% Create ylabel
ylabel(['Streamflow (' units{1} ')'],'Color',colors(1,:),'Interpreter','tex');

% Create second plot
yyaxis right; % varargin{:} goes on bar if needed
h2 = bar(time,prec,'FaceColor',colors(2,:),'EdgeColor','none',...
   'Tag','PrecipitationPlot');

% % With yyaxis, there is only one axis, so I don't track them separately
% ax2 = gca;
% ax2.Tag = 'PrecipitationAxis';

% Create ylabel
ylabel(['Precipitation (' units{2} ')'],'Color',colors(2,:),'Interpreter','tex');
axis(ax,'ij');

% return control to left axis
yyaxis left

% Set the remaining axes properties
% set(ax,'Color','none','XAxisLocation','top','XTickLabel','');
% ylim([0,1.5*ax.YLim(2)]);

% this should make the hyetograph and hydrograph not overlap

% this shouldn't be needed with yyaxis functionality
% ax2.XTick = ax1.XTick;

% Package output
H(1) = fig;
H(2) = ax;
H(3) = h1;
H(4) = h2;

%% create space between discharge and precip bars

% % method 1

% Calculate the ratio of the precipitation maximum to the streamflow maximum
% precip_flow_ratio = max(prec) / max(flow);

% Add extra space above the streamflow line based on the precip_flow_ratio
% ylim(ax, [ax.YLim(1), (1 + precip_flow_ratio) * ax.YLim(2)]);

% % method 2
% % I don't think this takes into consideration the axes in figure units
% % Loop through each time point and get overlap between precip bars and flow line
% max_overlap = 0;
% for n = 1:length(time)
%    overlap = prec(n) / ax.YLim(2) * flow(n);
%    if overlap > max_overlap
%       max_overlap = overlap;
%    end
% end
% % Add extra space above the streamflow line based on the max_overlap
% ylim(ax, [ax.YLim(1), (1 + max_overlap) * ax.YLim(2)]);

% % method 3

% Keep current ylims to reset the labels after making space for the precip bars
% ylims = ylim
% pick up on this, idea is to get the ylims and labels here, then after setting
% ylim([0,1.5*ax.YLim(2)]), reset the ticks to the original ones.

% ylim([ax.YLim(1),1.5*ax.YLim(2)]);

%% this stuff was in the original version, shouldn't be needed with yyaxis

% % make sure the top/bottom x-axes are linked
%     linkaxes([ax1 ax2],'x');
%     myaxistight([ax1 ax2],'x');

% move the y lables
% ypos1                   =   AX(1).YLabel.Position;
% ypos2                   =   AX(2).YLabel.Position;
% ypos1(2)                =   ypos1(2)/1.8;
% ypos2(2)                =   ypos2(2)/1.8;
% AX(1).YLabel.Position   =   ypos1;
% AX(2).YLabel.Position   =   ypos2;

%% below here is the original function

% [AX,H1,H2] = plotyy(dates,flow,dates,ppt,'plot','bar',varargin{:});
%
% % Set bar graph properties
% set(get(AX(2),'Ylabel'),'String','Precipitation (mm)','FontSize',16, ...
%         'Color',get(H2,'FaceColor'));
% set(AX(2),'XTickLabel',[],'xaxislocation','top','YDir','reverse');
%
% % Set line graph properties
% set(AX(1),'XTickLabel', []);
% set(AX(1),'FontSize',16);
% set(AX(1),'YColor','k');
% set(get(AX(1),'Ylabel'),'String','Streamflow (mm)','FontSize',16,...
%     'Color',get(H1,'Color'));
% % Print Month and Year as Tick Label
% % datetick(AX(1),'x','mmm yyyy')
% % datetick('x','mm/yy');
%
% % Edit begin
% % make sure the hyetograph and hydrograph don't overlap
% % First make both axes 2x as long
% AX(1).YLim(2)   =   2*AX(1).YLim(2);
% AX(2).YLim(2)   =   2*AX(2).YLim(2);
%
% % ylim1       =   AX(1).YLim;
% % ylim2       =   AX(2).YLim;
% % ymax1       =   max(flow(:,1));
% % ymax2       =   max(ppt(:,1));
% % scale       =   ylim2(2)/ylim1(2); % ratio of ppt/flow axis
% %
% % if ymax2 > ymax1
% % %     AX(2).YLim(2)   =   scale*(AX(2).YLim(2) + ymax1);
% %     AX(2).YLim(2)   =   AX(2).YLim(2) + (scale*ymax1);
% %     AX(1).YLim(2)   =   2*AX(1).YLim(2);
% % end
%
% % Edit end - 2x each axis seems to work
%
% % format x tick lables
% datetick('x','mmm-yyyy');
% % make sure the top/bottom x-axes are linked
% linkaxes([AX(2) AX(1)],'x');
% myaxistight(AX,'x');
% %
% grid on
% grid minor
%
% % move the y lables
% ypos1                   =   AX(1).YLabel.Position;
% ypos2                   =   AX(2).YLabel.Position;
% ypos1(2)                =   ypos1(2)/1.8;
% ypos2(2)                =   ypos2(2)/1.8;
% AX(1).YLabel.Position   =   ypos1;
% AX(2).YLabel.Position   =   ypos2;

