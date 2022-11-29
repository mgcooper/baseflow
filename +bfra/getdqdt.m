function [q,dqdt,dt,tq,rq,varargout] = getdqdt(T,Q,R,derivmethod,varargin)
%GETDQDT Numerical estimation of the time derivative of discharge dQ/dt
%using variable time stepping, exponential time stepping, or one of six
%standard numerical derivatives given in Thomas et al. 2015, Table 2
% 
%  Syntax
%     [q,dqdt,dt,tq,rq] = bfra.getdqdt(T,Q,R,derivmethod)
%     [q,dqdt,dt,tq,rq] = bfra.getdqdt(_,'fitwindow',fitwindow)
%     [q,dqdt,dt,tq,rq] = bfra.getdqdt(_,'fitwindow',fitmethod)
%     [q,dqdt,dt,tq,rq] = bfra.getdqdt(_,'pickmethod',pickmethod)
%     [q,dqdt,dt,tq,rq] = bfra.getdqdt(_,'ax',axis_object)
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
% 
% 
%  See also fitdqdt
% 
% Tip: this accepts pre-selected events, not raw timeseries. Use
% bfra.findevents to pick Events, then bfra.fitdqdt to fit the events.
% This is a wrapper for multi-year, final analysis.

%-------------------------------------------------------------------------------
% input handling    
p                 = inputParser;
p.FunctionName    = 'getdqdt';
p.CaseSensitive   = true;

addRequired(p, 'T',                    @(x) isnumeric(x) | isdatetime(x));
addRequired(p, 'Q',                    @(x) isnumeric(x)                );
addRequired(p, 'R',                    @(x) isnumeric(x)                );
addRequired(p, 'derivmethod',          @(x) ischar(x)                   );
addParameter(p,'vtsparam',    1,       @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'etsparam',    0.2,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'pickmethod',  'none',  @(x) ischar(x)                   );
addParameter(p,'fitmethod',   'nls',   @(x) ischar(x)                   );
addParameter(p,'plotfits',    false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'gageID',      'none',  @(x) ischar(x)                   );
addParameter(p,'eventID',     'none',  @(x) ischar(x)                   );
addParameter(p,'ax',          'none',  @(x) isaxis(x) | ischar(x)       );
addParameter(p,'flag',        false,   @(x) islogical(x)                );

parse(p,T,Q,R,derivmethod,varargin{:});

vtsparam    = p.Results.vtsparam;
etsparam    = p.Results.etsparam;
pickmethod  = p.Results.pickmethod;
fitmethod   = p.Results.fitmethod;
plotfits    = p.Results.plotfits;
gageID      = p.Results.gageID;
eventID     = p.Results.eventID;
ax          = p.Results.ax;
flag        = p.Results.flag;

% if isdatetime(T); T = datenum(T); end
%-------------------------------------------------------------------------------

   warning off

% process input
   [Q,T,R,exitFlag] = prepInput(Q,T,R);
   
% return to the main program if exitFlag is true
   if exitFlag == true
      q=nan(size(Q)); dt=q; dqdt=q; tq=q; rq=q;
      return;
   end
   
% apply the chosen method to find dQ/dt for the entire event
   [q,dqdt,dt,tq,rq,r] = bfra.fitdqdt(T,Q,R,derivmethod,'etsparam',etsparam,...
                           'vtsparam',vtsparam,'flag',flag);
   
% if we just want dQ/dt and q i.e. no fit, return from here
   if string(fitmethod) == "none"
      varargout{1} = nan; varargout{2} = nan;
      return;
   end

% % Nov 2022 - commented this out to see if it can be removed. I think we're
% effectively fitting every event twice with this active

% if pickmethod = "none", we don't need anything else so we could stop
% here, but go ahead and run fitSelector, it will return Info

   [q,dqdt,dt,tq,rq,hFits,~,~,Info] =  fitSelector(q,dqdt,dt,tq,r,      ...
                                       fitmethod,pickmethod,plotfits,   ...
                                       eventID,gageID);
      varargout{1}   = Info;
      varargout{2}   = hFits;

end

% ------------------------------------------------------------------------------
% FITSELECTOR
% ------------------------------------------------------------------------------
function [Q,dQdT,dT,T,R,hFits,Picks,Fits,Info] = fitSelector(q,dqdt,dt, ...
                                                   tq,rq,fitmethod,     ...
                                                   pickmethod,plotfits, ...
                                                   eventID,gageID)

% this is basically just a wrapper around bfra.plotdqdt
   
% select periods within an event (e.g., early-time, late-time) to send
% back to the main algorithm for fitting dq/dt = aQb
   [hFits,Picks,Fits]   = bfra.plotdqdt(q,dqdt, 'fitmethod',fitmethod,  ...
                                                'pickmethod',pickmethod,...
                                                'plotfits',plotfits,    ...
                                                'eventID',eventID,      ...
                                                'rain',rq);
   
% if no events are found, return nan
   if ~iscell(Picks.Q) && isnan(Picks.Q)
      T=nan;Q=nan;R=nan;dT=nan;dQdT=nan;Info=nan; return
   end
 
 
   numPicks = numel(Picks.Q);
   T     = cell(numPicks,1);
   Q     = cell(numPicks,1);
   R     = cell(numPicks,1);
   dT    = cell(numPicks,1);
   dQdT  = cell(numPicks,1);
   

   for m = 1:numPicks
      
      istart  = Picks.istart(m);
      istop   = Picks.istop(m);
      
      % previously these were put into Fits structure but I
      Q{m}     = q(istart:istop);
      dQdT{m}  = dqdt(istart:istop);
      dT{m}    = dt(istart:istop);
      T{m}     = tq(istart:istop);
      R        = rq(istart:istop);
      
      Info.istart(m)      = istart;
      Info.istop(m)       = istop;
      Info.runlengths(m)  = Picks.runlengths(m);
   end
end

% ------------------------------------------------------------------------------
% PREPINPUT
% ------------------------------------------------------------------------------

function [Q,T,R,exitFlag] = prepInput(Q,T,R)

   % convert to columns
   Q = Q(:); T = T(:); R = R(:);
   
   % if the input is all nan and/or zero, return the outputs as nan
   exitFlag=false; if sum(isnan(Q))+sum(Q==0)>=length(Q);exitFlag=true; end
   
end
