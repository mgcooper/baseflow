function [q,dqdt,dt,tq,rq,dq] = fitvts(T,Q,R,varargin)
   %FITVTS fit recession event using the variable timestep method
   %
   %  Syntax
   %
   %     VTS = fitvts(T,Q,R)
   %     VTS = fitvts(_,'vtsparam',vtsparam)
   %     VTS = fitvts(_,'plotfit',plotfit)
   %
   % Required inputs
   %
   %     T        : time (days)
   %     Q        : discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
   %     R        : rainfall (L T^-1, assumed to be mm d-1)
   %
   % Optional name-value inputs
   %
   %     vtsparam : scalar, double, parameter that controls window size
   %     plotfit  : logical, scalar, indicates whether to plot the fit
   %
   % This code is based on the method described in:
   % Rupp, D. E. and Selker, J. S.: Information, artifacts, and noise in dQ/dt −
   % Q recession analysis, Advances in Water Resources, 29, 154–160,
   % https://doi.org/10.1016/j.advwatres.2005.03.019, 2006.
   %
   % See also fitdqdt, fitets
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % PARSE INPUTS
   [T, Q, R, vtsparam, plotfit] = parseinputs(T, Q, R, varargin{:});

   % the C value should be chosen such that dt(i) = t(i)-t(i-j) <= t(i)/4
   % the limit value is limit = C*(Q(H+e)-Qi)) where H is stage height, e
   % is stage precision, and Qi is the estimated Q. To implement this, I
   % need e and the stage-discharge relation.

   % prep the time vector
   t = T - T(1) + (T(2)-T(1)); % keep og T

   % For datetimes:
   % t = days(T-T(1)+(T(2)-T(1))); % keep og T

   % initialize the approximations for dq/dt and Q (and dq and dt)
   [N,q,dqdt,dq,dt,tq,rq] = initfit(Q,'eventdqdt');

   % if the input flow is less than the dq limit, decrease the limit
   if mean(Q,'omitnan') < vtsparam                   % could use nanmax
      vtsparam = min(Q(Q>0),[],'omitnan')*vtsparam;
      while mean(Q,'omitnan') < vtsparam
         vtsparam = 0.9*vtsparam;              % decrease by 10%
      end
   end

   for n = 2:N
      for m = 1:n-1 % go back i-1 steps until the limit criteria is met

         dq(n) = Q(n) - Q(n-m);
         % see notes at end on C criteria from Rupp and Selker

         % dq is zero or (+), or is (-) and meets the limit criteria
         if dq(n) >= 0 || round(abs(dq(n))) > vtsparam
            q(n)     = 1/(m+1) * sum(Q(n-m:n));
            tq(n)    = mean(T(n-m:n)); % 1/(m+1) * sum(t(n-m:n));
            rq(n)    = 1/(m+1) * sum(R(n-m:n)); % rain
            dt(n)    = t(n) - t(n-m);
            dqdt(n)  = dq(n)/dt(n);
            break
         else % dqdt is (-) and does not meet the limit criteria
            dq(n)   = nan; % NOTE: this must be reset to nan
            continue % continue until it meets the criteria
         end
      end
   end

   % retime to the original timestep
   % tq    = T(1) + days(tq);
   % q     = interp1(tq(~isnan(q)),q(~isnan(q)),T);
   % dq    = interp1(tq(~isnan(dq)),dq(~isnan(dq)),T);
   % dqdt  = interp1(tq(~isnan(dqdt)),dqdt(~isnan(dqdt)),T);

   % Patch: post the estimates on the original time vector. It is unclear
   % what value should be used, but anything other than the original time
   % complicates subsequent identification of events.
   tq = T;

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


end

%% INPUT PARSER
function [T, Q, R, vtsparam, plotfit] = parseinputs(T, Q, R, varargin)
   parser = inputParser;
   parser.FunctionName = 'fitvts';

   parser.addRequired('T', @(x) isnumeric(x) || isdatetime(x));
   parser.addRequired('Q', @isnumeric);
   parser.addRequired('R', @isnumeric);
   parser.addParameter('vtsparam', 1, @isnumeric); % default=1 m3/d
   parser.addParameter('plotfit', false, @islogical);

   parser.parse(T, Q, R, varargin{:});

   vtsparam = parser.Results.vtsparam;
   plotfit  = parser.Results.plotfit;

end
