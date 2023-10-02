function [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A,varargin)
   %BASEFLOWTREND Estimate baseflow trend from annual streamflow timeseries.
   %
   % Syntax
   %
   %     [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A)
   %
   % Description
   %
   %     [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A) Computes annual values
   %     of baseflow Qb, the linear trend in annual baseflow dQbdt, annual
   %     streamflow anomalies Qa, and the linear trend in annual streamflow
   %     anomalies dQadt, using quantile regression on the annual streamflow
   %     timeseries.
   %
   % Required inputs
   %
   %     t: time [days], numeric or datetime vector
   %     Q: discharge [m3/d], posted daily, numeric vector
   %     A: basin area [m2], numeric scalar
   %
   % Outputs
   %
   %     Qb: baseflow expected value [cm/d], posted annually, numeric vector
   %     dQbdt: baseflow expected value trend [cm/d], posted annually, numeric
   %     vector (the trend evaluated at each year in the input t timeseries) Q:
   %     discharge [cm/d], posted annually (input Q converted to units cm/d/y)
   %     dQadt: discharge trend [cm/d], posted annually (the trend in discharge
   %     evaluated at each year in the input t timeseries) hb: figure handle for
   %     the baseflow trendplot figure ha: figure handle for the annual flow
   %     trendplot figure
   %
   % See also: aquiferthickness
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [t, Q, A, method, pctl, showfig] = parseinputs(t, Q, A, varargin{:});

   % MAIN FUNCTION
   t1 = datenum(year(t(1)), 1, 1, 0, 0, 0);
   t2 = datenum(year(t(end)), 12, 31, 0, 0, 0);
   [Q, t] = padtimeseries(Q, t, t1, t2, 1); %#ok<*DATNM>
   [Q, t] = rmleapinds(Q, t);

   % convert the flow from m3/d posted daily to cm/d posted annually
   %if ~isdatetime(t); t = datetime(t,'ConvertFrom','datenum'); end
   t = transpose(year(mean(reshape(t, 365, numel(t) / 365))));
   Qa = transpose(mean(reshape(Q, 365, numel(Q) / 365), 'omitnan')) .* (100/A);

   % regress Q [cm/d/y] against t [y] to get the trend [cm/d] posted annually
   ha = baseflow.trendplot(t, Qa, 'anomalies', false, 'units', 'cm/d/y', ...
      'titletext', 'mean flow', 'legendtext', 'mean flow regression', ...
      'showfig', showfig, 'method', method);
   hb = baseflow.trendplot(t, Qa, 'anomalies', false, 'units', 'cm/d/y', ...
      'quantile', pctl, 'titletext', 'baseflow', 'legendtext', ...
      'baseflow regression', 'showfig', showfig, 'alpha', 0.05);
   dQadt = reshape(get(ha.trend, 'YData'), [], 1); % mean flow trend
   dQbdt = reshape(get(hb.trend, 'YData'), [], 1); % baseflow trend
   Qb = Qa-(dQadt-dQbdt); % baseflow timeseries, cm/day
end

%% INPUT PARSER
function [t, Q, A, method, prctle, showfig] = parseinputs(t, Q, A, varargin)

   parser = inputParser;
   parser.FunctionName = 'baseflow.baseflowtrend';
   parser.addRequired('t', @isdatelike);
   parser.addRequired('Q', @isnumericvector);
   parser.addRequired('A', @isnumericscalar);
   parser.addParameter('method', 'ols', @ischarlike);
   parser.addParameter('pctl', 0.25, @isnumericscalar);
   parser.addParameter('showfig', false, @islogicalscalar);
   parser.parse(t,Q,A,varargin{:});

   % Convert datetime to double if datetime was passed in
   t = todatenum(t);

   method = parser.Results.method;
   prctle = parser.Results.pctl;
   showfig = parser.Results.showfig;
end
