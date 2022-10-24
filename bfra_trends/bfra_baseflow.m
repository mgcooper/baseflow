function [Qb,dQbdt,Q,dQadt,hbtrend,hatrend] = bfra_baseflow(t,Q,varargin)
%bfra_baseflow computes the expected value of baseflow and rate of change
%posted on an annual basis
% Inputs:
%  t = time, posted annually [years]
%  Q = mean daily discharge, posted annually [cm/day]

%-------------------------------------------------------------------------------
p=MipInputParser;
p.FunctionName='bfra_baseflow';
p.PartialMatching = true;
p.addRequired('t',@(x)isdatetime(x)|isnumeric(x));
p.addRequired('Q',@(x)isnumeric(x));
p.addParameter('method','ols',@(x)ischar(x));
p.addParameter('pctl',0.25,@(x)isnumeric(x));
p.addParameter('showfig',false,@(x)islogical(x));
p.parseMagically('caller');
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
   