function [q,dqdt,dt,tq,rq,dq,tqmid] = fitcts(T,Q,R,varargin)
   %FITCTS fit q/dqdt with a finite difference on a constant time step.
   %
   % Syntax
   %
   %     [q,dqdt,dt,tq,rq,dq,tqmid] = fitcts(T,Q,R)
   %     [q,dqdt,dt,tq,rq,dq,tqmid] = fitcts(T,Q,R,method)
   %
   % Description
   %
   %     fitcts computes the recession rate dQ/dt on the fixed sample time
   %     step. This is the traditional method of Brutsaert and Nieber (1977),
   %     in which daily flow differences approximate the derivative. The ETS
   %     (fitets) and VTS (fitvts) methods refine this method. fitcts is the
   %     constant-time-step baseline to compare them against.
   %
   %     method selects the finite-difference stencil:
   %
   %        'B1'  backward, first order (the traditional choice; default)
   %        'B2'  backward, second order
   %        'F1'  forward, first order
   %        'F2'  forward, second order
   %        'C2'  centered, second order
   %        'C4'  centered, fourth order
   %
   %     Outputs q (stencil-averaged flow), dqdt (dq./dt), dt (the
   %     constant step), tq (the input time vector, see the note below),
   %     rq (rain posted on the same time vector), dq (the raw
   %     difference), and tqmid (the midpoint times of the flow average q).
   %     For B1, F1, C2, and C4, dqdt also estimates the derivative at
   %     tqmid. For B2 and F2, dqdt estimates the derivative at tq, and
   %     tqmid is half a step earlier (B2) or later (F2). Stencil edge
   %     samples are nan. A single sample has no time step, so q, dqdt,
   %     dt, dq, and tqmid are nan.
   %
   % See also: fitets, fitvts, getdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % NOTE: to use any of these that involve more than 1 timestep
   % forward or backward, I'll need to adjust findevents to return a
   % longer timeseries

   % Validate the stencil; 'B1' is the traditional backward difference.
   if nargin < 4 || isempty(varargin{1})
      method = 'B1';
   else
      method = validatestring(varargin{1}, ...
         {'B1','B2','F1','F2','C2','C4'}, mfilename, 'method', 4);
   end

   % prep for fitting
   T = T(:); Q = Q(:); R = R(:);

   % A constant time step requires a uniform time vector. Allow roundoff
   % error in datenum inputs, but reject real gaps or cadence changes.
   % One shared dt is wrong for every stencil in those cases.
   dtall = diff(T);
   dt0 = median(dtall);
   if any(abs(dtall - dt0) > 1e-6*max(abs(dt0), 1))
      error('baseflow:fitcts:nonuniformTime', ...
         'fitcts requires a uniform time vector; use the ETS or VTS method')
   end
   dt = dt0 * ones(size(T));

   % offset vectors to compute derivatives. Build the two-step offsets from
   % the one-step offsets so each vector matches the length of Q, also for
   % a single sample.
   Qi = Q;
   Qim1 = [nan; Qi(1:end-1)];       % i minus 1
   Qim2 = [nan; Qim1(1:end-1)];     % i minus 2
   Qip1 = [Qi(2:end); nan];         % i plus 1
   Qip2 = [Qip1(2:end); nan];       % i plus 2

   Ti = T;                          % new
   Tim1 = [nan; Ti(1:end-1)];       % i minus 1
   Tip1 = [Ti(2:end); nan];         % i plus 1

   % % forward, backward, and centered mean flow
   % Qfwd = (Qi+Qip1)./2./dt;
   % Qbwd = (Qi+Qim1)./2./dt;
   % Qctr = (Qip1+Qim1)./2./dt;

   % not sure why the /dt's are above, maybe before I did dqdt = dq/dt
   % at the end (since those values are the average flow over two steps)
   Qfwd = (Qi+Qip1) / 2;
   Qbwd = (Qi+Qim1) / 2;
   Qctr = (Qip1+Qim1) / 2;

   % forward, backward, and centered midpoint times, the natural posting
   % for the stencil-averaged flow
   Tbwd = (Ti+Tim1) / 2;            % new
   Tfwd = (Ti+Tip1) / 2;
   Tctr = (Tip1+Tim1) / 2;

   switch method
      case 'B1'                                 % backward, version 1
         dq  = Qi-Qim1;
         q   = Qbwd;
         tqmid = Tbwd;
      case 'B2'                                 % backward, version 2
         dq  = (3*Qi - 4*Qim1 + Qim2) / 2;
         q   = Qbwd;
         tqmid = Tbwd;
      case 'F1'                                 % forward, version 1
         dq  = Qip1-Qi;
         q   = Qfwd;
         tqmid = Tfwd;
      case 'F2'                                 % forward, version 2
         dq  = (-Qip2+4 .* Qip1 - 3*Qi) / 2;
         q   = Qfwd;
         tqmid = Tfwd;
      case 'C2'                                 % centered, version 1
         dq  = (Qip1-Qim1) / 2;
         q   = Qctr;
         tqmid = Tctr;
      case 'C4'                                 % centered, version 2
         dq  = (-Qip2 + 8*Qip1 - 8*Qim1 + Qim2) / 12;
         q   = Qctr;
         tqmid = Tctr;
   end
   dqdt = dq./dt;

   % Rain posts on the same time vector as tq, as in the ETS method.
   rq = R;

   % Post the estimates on the original time vector. The natural posting
   % is the stencil midpoint, returned as tqmid, but any other time vector
   % makes it harder to identify events later.
   tq = T;
end
