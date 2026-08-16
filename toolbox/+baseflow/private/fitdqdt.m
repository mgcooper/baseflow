function [q,dqdt,dt,tq,rq,r] = fitdqdt(T,Q,R,method,varargin)
   %FITDQDT estimate event-scale recession q and first-derivative dqdt
   %
   %  Syntax
   %
   %     [q,dqdt,dt,tq,rq,r] = baseflow.fitdqdt(T,Q,R,derivmethod)
   %     [q,dqdt,dt,tq,rq,r] = baseflow.fitdqdt(_,'fitwindow',fitwindow)
   %     [q,dqdt,dt,tq,rq,r] = baseflow.fitdqdt(_,'fitwindow',fitmethod)
   %     [q,dqdt,dt,tq,rq,r] = baseflow.fitdqdt(_,'pickmethod',pickmethod)
   %     [q,dqdt,dt,tq,rq,r] = baseflow.fitdqdt(_,'ax',axis_object)
   %
   % Description
   %
   %     Prepare q and dq/dt for recession events to send to fitab.
   %
   %  Required inputs
   %
   %     T     =  time (days)
   %     Q     =  discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
   %     R     =  rainfall (L T^-1, assumed to be mm d-1)
   %     derivmethod = method to compute numerical derivative dQ/dt. Options are
   %     'VTS','ETS','B1','B2','F1','F2','C2','C4','SGO','SPN','SLM'. default: ETS
   %
   %  Optional name-value inputs
   %
   %     etsparam =  scalar double, parameter that controls window size in ETS method
   %     vtsparam =  scalar double, parameter that controls window size in VTS method
   %     fitab    =  logical, scalar, indicates whether to fit a/b in -dQ/dt=aQb
   %     plotfit  =  logical, scalar, indicates whether to plot the fit
   %
   %  See also getdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % input parsing
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

   % Jul 2024 - set these to suppress codeissues
   [q,dqdt,dt,tq,rq,r] = deal([], [], [], [], [], []);
end
