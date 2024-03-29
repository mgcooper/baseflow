function H = hyetograph(time, flow, prec, varargin)
   %HYETOGRAPH Plot a discharge rainfall hyetograph.
   %
   %  H = hyetograph(time,flow,ppt) plots hyetograph using data in flow and ppt
   %
   %  H = hyetograph(time,flow,ppt,t1,t2) plots hyetograph using data in flow
   %  and ppt for time period bounded by datetimes t1 and t2
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
   % See also:

   % if called with no input, open this file
   if nargin == 0; open([mfilename('fullpath'),'.m']); return; end

   % parse inputs
   [time, flow, prec, t1, t2, units, fig] = parseinputs(mfilename, time, flow, ...
      prec, varargin{:});


   % initialize container for output handles
   if isoctave
      H = zeros(4,1);
   else
      H = gobjects(4,1); % figure, ax1, plot1, plot2
   end

   % Set the figure handle tag
   set(fig, 'Name', 'Hyetograph', 'Tag', 'HyetographFigure');

   % convert to columns
   time = time(:);
   prec = prec(:);
   flow = flow(:);

   % convert to datetime
   if ~isoctave
      if ~isdatetime(time); time = datetime(time, 'ConvertFrom', 'datenum'); end
      if ~isdatetime(t1); t1 = datetime(t1, 'ConvertFrom', 'datenum'); end
      if ~isdatetime(t2); t2 = datetime(t2, 'ConvertFrom', 'datenum'); end

      % trim to t1,t2 timespan
      prec = prec(isbetween(time, t1, t2));
      flow = flow(isbetween(time, t1, t2));
      time = time(isbetween(time, t1, t2));
   else
      prec = prec(t1 < time & time < t2);
      flow = flow(t1 < time & time < t2);
      time = time(t1 < time & time < t2);
   end

   % process units
   units = siUnitsToTex(units);

   % get default colors
   colors = get(0, 'defaultaxescolororder');

   % Create plot
   [ax, h1, h2] = plotyy(time, flow, time, prec, @plot, @bar); %#ok<*PLOTYY>

   if isoctave
      datetick(ax(1),'x','mmm-yy','keeplimits')
      datetick(ax(2),'x','mmm-yy','keeplimits')
   else
      datetick(ax(1),'x','mmm-yy','keepticks')
      datetick(ax(2),'x','mmm-yy','keepticks')
   end

   % Set line graph properties
   set(h1, 'LineStyle', '-', 'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', ...
      colors(1,:), 'MarkerEdgeColor', 'none', 'Tag', 'StreamflowPlot');
   set(ax(1), 'YColor', 'k', 'XMinorGrid', 'on', 'YMinorGrid', ...
      'on', 'FontSize', 12, 'Tag', 'HyetographAxis');
   ylabel(ax(1), ['Streamflow (' units{1} ')'], 'Color', colors(1,:), ...
      'FontSize', 12, 'Interpreter', 'tex');
   grid(ax(1), 'on');

   % Set bar graph properties
   set(h2, 'FaceColor', colors(2,:), 'EdgeColor', 'none', 'Tag', 'PrecipitationPlot');
   set(ax(2), 'XTickLabel', [], 'xaxislocation', 'top', 'YDir', 'reverse', ...
      'FontSize', 12);
   ylabel(ax(2), ['Precipitation (' units{2} ')'], 'Color', colors(2,:), ...
      'FontSize', 12, 'Interpreter', 'tex');

   % Reduce the width to make room for the ylabel on the right
   set(ax(1), 'Position', [0.13 0.13 0.72 0.8]);
   set(ax(2), 'Position', [0.13 0.13 0.72 0.8]);

   set(ax(2), 'XLim', get(ax(1), 'XLim'), 'XTick', get(ax(1), 'XTick'));

   % Package output
   H(1) = fig;
   H(2) = ax(1);
   H(3) = h1;
   H(4) = h2;
   
   if ~isoctave
      % Set up listener to trigger setlogticks if YScale is set to 'log'
      addlistener(ax(1), 'YScale', 'PostSet', @(s, e) triggerLogScale(s, e, ax(1)));
      
      % Set up listener to trigger interpreter if labels are updated
      addlistener(ax(1), 'YLabel', 'PostSet', @(s, e) triggerInterpreter(s, e, ax(1)));
   
      % Set up listener to trigger interpreter if labels are updated so the
      % interpreter is set to 'tex' if isoctave() returns true, and 'latex'
      % otherwise. 
      % addlistener(ax(1), 'YScale', 'PostSet', @(s, e) triggerInterpreter(s, e, ax(1)));
      
      % this is the example syntax from octave, not sure if its helpful
      % addlistener(gcf, "position", {@my_listener, "my string"})
   end
end

% Listener function to handle YScale change
function triggerLogScale(~, ~, ax)
  if strcmp(get(ax, 'YScale'), 'log')
    setlogticks(ax, 'axset', 'y');
  end
end

% Listener function to handle Interpreter change
function triggerInterpreter(~, ~, ax)
   labelHandle = get(ax, 'YLabel');
   interpreterSetting = get(labelHandle, 'Interpreter');

   if isoctave() && strcmp(interpreterSetting, 'latex')
      set(labelHandle, 'Interpreter', 'tex');
   end
end

%% Input Parser
function [time, flow, prec, t1, t2, units, fig] = parseinputs(funcname, ...
      time, flow, prec, varargin)

   % parse graphics handle if provided
   tf = cellfun(@(arg) isscalar(arg) && ishandle(arg) && ...
      strcmp('axes', get(arg,'type')), varargin);

   if any(tf)
      ax = varargin{tf};
      fig = get(ax, 'Parent');
      varargin = varargin(~tf);
   else
      fig = gcf;
   end
   
   set(fig, 'Position', [0 0 700 400]);

   parser = inputParser;
   parser.FunctionName = funcname;
   parser.addRequired('time', @isdatelike);
   parser.addRequired('flow', @isnumericvector);
   parser.addRequired('prec', @isnumericvector);
   parser.addOptional('t1', NaT, @isdatelike);
   parser.addOptional('t2', NaT, @isdatelike);
   parser.addParameter('units', {'mm','cm d-1'}, @ischarlike);

   parser.parse(time,flow,prec,varargin{:});

   time = parser.Results.time;
   flow = parser.Results.flow;
   prec = parser.Results.prec;
   t1 = parser.Results.t1;
   t2 = parser.Results.t2;
   units = parser.Results.units;
   
   time = todatenum(time);
end

% =======================================
% Create plot
% yyaxis left;
% h1 = plot(time,flow,'-o','MarkerSize',4,'MarkerFaceColor',colors(1,:), ...
%    'MarkerEdgeColor','none','Tag','StreamflowPlot');
% ax = gca;
% set(ax,'Tag','HyetographAxis');
%
% % % With yyaxis, there is only one axis, so I don't track them separately
% % ax1 = gca;
% % ax1.Tag = 'StreamflowAxis';
%
% % Set the remaining axes properties
% set(ax,'XMinorGrid','on','YMinorGrid','on');
% grid(ax,'on');
%
% % hacky way to make space so the precip bars do not obscure the streamflow
% % ylim([ax.YLim(1),1.5*ax.YLim(2)]);
%
% % Create ylabel
% ylabel(['Streamflow (' units{1} ')'],'Color',colors(1,:),'Interpreter','tex');
%
% % Create second plot
% yyaxis right; % varargin{:} goes on bar if needed
% h2 = bar(time,prec,'FaceColor',colors(2,:),'EdgeColor','none',...
%    'Tag','PrecipitationPlot');
%
% % % With yyaxis, there is only one axis, so I don't track them separately
% % ax2 = gca;
% % ax2.Tag = 'PrecipitationAxis';
%
% % Create ylabel
% ylabel(['Precipitation (' units{2} ')'],'Color',colors(2,:),'Interpreter','tex');
% axis(ax,'ij');
%
% % return control to left axis
% yyaxis left
% =======================================

