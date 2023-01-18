function [q,dqdt,dt,tq,rq,r] = fitdqdt(T,Q,R,method,varargin)
%FITDQDT estimate q and dqdt during recession events to send to fitab
% 
%  Syntax
%     [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(T,Q,R,derivmethod)
%     [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(_,'fitwindow',fitwindow)
%     [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(_,'fitwindow',fitmethod)
%     [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(_,'pickmethod',pickmethod)
%     [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(_,'ax',axis_object)
% 
%  Required inputs
%     T     =  time (days)
%     Q     =  discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
%     R     =  rainfall (L T^-1, assumed to be mm d-1)
%     derivmethod = method to compute numerical derivative dQ/dt. Options are
%     'VTS','ETS','B1','B2','F1','F2','C2','C4','SGO','SPN','SLM'. default: ETS
% 
%  Optional name-value pairs
% 
%     etsparam =  scalar double, parameter that controls window size in ETS method
%     vtsparam =  scalar double, parameter that controls window size in VTS method
%     fitab    =  logical, scalar, indicates whether to fit a/b in -dQ/dt=aQb
%     plotfit  =  logical, scalar, indicates whether to plot the fit
% 
%  See also getdqdt

% input parsing
%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'fitdqdt';

addRequired(p,    'T',                 @(x)isnumeric(x)|isdatetime(x));
addRequired(p,    'Q',                 @(x)isnumeric(x)  );
addRequired(p,    'R',                 @(x)isnumeric(x)  );
addRequired(p,    'method',            @(x)ischar(x)     );
addParameter(p,   'etsparam'  ,0.2,    @(x)isnumeric(x)  );   % default=recommended 20%
addParameter(p,   'vtsparam', 1,       @(x)isnumeric(x)  );     % vts min flow
addParameter(p,   'fitab',    false,   @(x)islogical(x)  );
addParameter(p,   'plotfit',  false,   @(x)islogical(x)  );
addParameter(p,   'flag',     false,   @(x) islogical(x) );

parse(p,T,Q,R,method,varargin{:});

etsparam = p.Results.etsparam;
vtsparam = p.Results.vtsparam;
fitab    = p.Results.fitab;
plotfit  = p.Results.plotfit;
flag     = p.Results.flag;
%-------------------------------------------------------------------------------

