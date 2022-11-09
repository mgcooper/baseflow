function [Qb,dQbdt,Q,dQadt,hbtrend,hatrend] = baseflow(t,Q,varargin)
%BASEFLOW computes the expected value of baseflow and rate of change
%posted on an annual basis
% 
%  Inputs
% 
%     t = time, posted annually [years]
%     Q = mean daily discharge, posted annually [cm/day]

%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.baseflow';

addRequired(   p,    't',                 @(x)isdatetime(x)|isnumeric(x)   );
addRequired(   p,    'Q',                 @(x)isnumeric(x)                 );
addParameter(  p,    'method',   'ols',   @(x)ischar(x)                    );
addParameter(  p,    'pctl',     0.25,    @(x)isnumeric(x)                 );
addParameter(  p,    'showfig',  false,   @(x)islogical(x)                 );

parse(p,t,Q,varargin{:});

if ~isdatetime(t); t = datetime(t,'convertfrom','datenum'); end
%-------------------------------------------------------------------------------

% flow comes in as cm/day, posted annually, regressed against t in
% years, so the trend is in cm/day/year

% get the baseflow trend, adjusted as an anomaly
hatrend  = trendplot(t,Q,'anom',false,'units','cm/d/y',             ...
            'title','mean flow','leg','mean flow regression',        ...
            'showfig',showfig,'method',method);
hbtrend  = trendplot(t,Q,'anom',false,'units','cm/d/y','quan',      ...
            pctl,'title','baseflow','leg','baseflow regression',    ...
            'showfig',showfig);
dQadt    = hatrend.trend.YData(:);  % mean flow trend         
dQbdt    = hbtrend.trend.YData(:);  % baseflow trend     
Qb       = Q-(dQadt-dQbdt);         % baseflow timeseries, cm/day  
   