function [q,dqdt,dt,tq,rq,dq] = fitvts(T,Q,R,varargin)
%FITVTS fits recession event using the variable timestep method
%
%  Syntax
%     VTS = bfra.fitvts(T,Q,R)
%     VTS = bfra.fitvts(___,'vtsparam',vtsparam)
%     VTS = bfra.fitvts(___,'plotfit',plotfit)
%
%  Required inputs
%     T        : time (days)
%     Q        : discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
%     R        : rainfall (L T^-1, assumed to be mm d-1)
%
%  Optional name-value pairs
%     vtsparam : scalar, double, parameter that controls window size
%     plotfit  : logical, scalar, indicates whether to plot the fit
%
%  See also fitdqdt, fitets

%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'fitvts';

addRequired(p, 'T',                 @(x)isnumeric(x)|isdatetime(x));
addRequired(p, 'Q',                 @(x)isnumeric(x));
addRequired(p, 'R',                 @(x)isnumeric(x));
addParameter(p,'vtsparam', 86400,   @(x)isnumeric(x)); % default=1 m3/d
addParameter(p,'plotfit',  false,   @(x)islogical(x));

parse(p,T,Q,R,varargin{:});

vtsparam = p.Results.vtsparam;
plotfit  = p.Results.plotfit;
%-------------------------------------------------------------------------------

% the C value should be chosen such that dt(i) = t(i)-t(i-j) <= t(i)/4
% the limit value is limit = C*(Q(H+e)-Qi)) where H is stage height, e
% is stage precision, and Qi is the estimated Q. To implement this, I
% need e and the stage-discharge relation. In lieu, I use a minimum
% discharge precision of 1 m3/s converted to m3/d

% initialize the approximations for dq/dt and Q (and dq and dt)
q       = nan(size(Q));
dq      = nan(size(Q));
dt      = nan(size(Q));
dqdt    = nan(size(Q));
tq      = nan(size(Q));
rq      = nan(size(Q));

% if the input flow is less than the dq limit, decrease the limit
if mean(Q,'omitnan') < vtsparam                   % could use nanmax
   vtsparam = min(Q(Q>0),[],'omitnan')*vtsparam;
   while mean(Q,'omitnan') < vtsparam
      vtsparam = 0.9*vtsparam;              % decrease by 10%
   end
end

% this note was in an older version, not sure if it is relevant: this makes t
% go from 1:length(q). I commented it out in case we want datenums returned:
% t = t-t(1)+1;

for n = 2:length(T)
   for m = 1:n-1 % go back i-1 steps until the limit criteria is met
      
      dq(n)   = Q(n) - Q(n-m);
      % see notes at end on C criteria from Rupp and Selker
      
      % dq is zero or (+), or is (-) and meets the limit criteria
      if dq(n) >= 0 || round(abs(dq(n)),1) > vtsparam
         q(n)    = 1/(m+1) * sum(Q(n-m:n));
         tq(n)   = 1/(m+1) * sum(T(n-m:n)); % new
         rq(n)   = 1/(m+1) * sum(R(n-m:n)); % new
         dt(n)   = T(n) - T(n-m);
         dqdt(n) = dq(n)/dt(n);
         break
      else % dqdt is (-) and does not meet the limit criteria
         dq(n)   = nan; % NOTE: this must be reset to nan
         continue % continue until it meets the criteria
      end
   end
end

if plotfit == true
   
   % option to plot would go here
   
end
   


% NOTES ON C-CRITERIA test C criteria the C criteria is that dt<ti/4, where
% dt is t(i)-t(i-j) and ti is time since start of recession. currently i am
% not tracking the start/end of each recession period, I am just treating
% each dQ = Q(i)-Q(i-1) as a change in Q, and applying the variable dt
% criteria, aiming to then later identify actual recessions, so i might
% need to rethink this and find a way to identify the start of a recession
% event, and then count forward from there for each dQ, where the number of
% timesteps counting forward would be ti, and the variable dt would be
% ti_j, and then I could check that ti_j<=ti/4
   
%    tn    =   t(n);
%    tn_m  =   t(n-m);
%    
%    if 4*(tn-tn_m)
%    if 4*(t(n) - t(n-m));