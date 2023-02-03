function [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A,varargin)
%BASEFLOWTREND compute baseflow expected value and rate of change
% 
% Syntax
% 
%     [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A,varargin)
% 
% Description
% 
%     [Qb,dQbdt,Qa,dQadt,hb,ha] = baseflowtrend(t,Q,A) computes annual values of
%     baseflow Qb, the linear trend in annual baseflow dQbdt, annual streamflow
%     anomalies Qa, and the linear trend in annual streamflow anomalies dQadt.
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
%     vector (the trend evaluated at each year in the input t timeseries)
%     Q: discharge [cm/d], posted annually (input Q converted to units cm/d/y)
%     dQadt: discharge trend [cm/d], posted annually (the trend in discharge
%     evaluated at each year in the input t timeseries)
%     hb: figure handle for the baseflow trendplot figure
%     ha: figure handle for the annual flow trendplot figure
% 
% See also aquiferthickness
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.baseflowtrend';

addRequired(   p,    't',                 @(x)isdatetime(x)|isnumeric(x)   );
addRequired(   p,    'Q',                 @(x)isnumericvector(x)           );
addRequired(   p,    'A',                 @(x)isnumericscalar(x)           );
addParameter(  p,    'method',   'ols',   @(x)ischar(x)                    );
addParameter(  p,    'pctl',     0.25,    @(x)isnumeric(x)                 );
addParameter(  p,    'showfig',  false,   @(x)islogical(x)                 );

parse(p,t,Q,A,varargin{:});

method   = p.Results.method;
pctl     = p.Results.pctl;
showfig  = p.Results.showfig;

%-------------------------------------------------------------------------------

[Q,t] = padtimeseries(Q,t,datenum(year(t(1)),1,1),datenum(year(t(end)),12,31),1);
[Q,t] = rmleapinds(Q,t);

% convert the flow from m3/d posted daily to cm/d posted annually
if ~isdatetime(t); t = datetime(t,'ConvertFrom','datenum'); end
t = transpose(year(mean(reshape(t,365,numel(t)/365))));
Qa = transpose(mean(reshape(Q,365,numel(Q)/365),'omitnan')).*(100/A);

% regress Q [cm/d/y] against t [y] to get the trend [cm/d] posted annually
ha  = trendplot(t,Qa,'anom',false,'units','cm/d/y',             ...
            'title','mean flow','leg','mean flow regression',        ...
            'showfig',showfig,'method',method);
hb  = trendplot(t,Qa,'anom',false,'units','cm/d/y','quan',      ...
            pctl,'title','baseflow','leg','baseflow regression',    ...
            'showfig',showfig,'alpha',0.05);
dQadt    = ha.trend.YData(:);  % mean flow trend         
dQbdt    = hb.trend.YData(:);  % baseflow trend     
Qb       = Qa-(dQadt-dQbdt);         % baseflow timeseries, cm/day  
   
