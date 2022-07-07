
function [q,dqdt,dt,tq,rq,r] = bfra_fitdqdt(T,Q,R,method,varargin)
%BFRA_FITDQDT
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% input parsing
p = MipInputParser;
p.FunctionName = 'bfra_fitdqdt';
p.addRequired('T',@(x)isnumeric(x)|isdatetime(x));
p.addRequired('Q',@(x)isnumeric(x));
p.addRequired('R',@(x)isnumeric(x));
p.addRequired('method',@(x)ischar(x));
p.addParameter('window',1,@(x)isnumeric(x));    
p.addParameter('etsparam',0.2,@(x)isnumeric(x));   % default=recommended 20%
p.addParameter('vtsparam',1,@(x)isnumeric(x));     % vts min flow
p.addParameter('fitab',true,@(x)islogical(x));
p.addParameter('plotfit',false,@(x)islogical(x));
p.parseMagically('caller');
plotfit = p.Results.plotfit; % otherwise builtin plotfit is called
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Todo: call the individual fitVTS, fitETS, etc. functions
% added 'Fit' output to access the original data that gets retimed in ets,
% need to decide if just passing back a strucutre is better for all opts
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   % temporary patch, for event-based fitting, i want the actual rain, not
   % rq, but that's only implemented for ETS, so return empty otherwise
   r       = [];

   % initialize the approximations for dq/dt and Q (and dq and dt)
   q       = nan(size(Q));
   dq      = nan(size(Q));
   dt      = nan(size(Q));
   dqdt    = nan(size(Q));
   tq      = nan(size(Q));
   rq      = nan(size(Q));
   
   if strcmp(method,'VTS') % variable time step
      
      % if the input flow is less than the dq limit, decrease the limit
      if nanmean(Q) < vtsparam                   % could use nanmax
         vtsparam = nanmin(Q(Q>0))*vtsparam;
         while nanmean(Q) < vtsparam
            vtsparam = 0.9*vtsparam;              % decrease by 10%
         end
      end
      
      for n = 2:length(T)
         for m = 1:n-1 % go back i-1 steps until the limit criteria is met
            
            dq(n)   = Q(n) - Q(n-m);
            % see notes at end on C criteria from Rupp and Selker
            
            % dq is zero or (+), or is (-) and meets the limit criteria
            if dq(n) >= 0 || roundn(abs(dq(n)),-1) > vtsparam
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
      
   elseif strcmp(method,'ETS')
      
      % this assumes the event t,q are passed in
      Fit     =   bfra_fitETS(T,Q,R,'nsteps',etsparam,'fitab',fitab,'plot',plotfit);
      q       =   Fit.T.q;
      dq      =   Fit.T.dq;
      dt      =   Fit.T.dt;
      dqdt    =   Fit.T.dqdt;
     %rq      =   Fit.T.rq;
      tq      =   Fit.T.Time;
      r       =   Fit.T.R;
      
      
      % Constant time step, 6 numerical derivatives (Thomas et al 2015)
   elseif any(strcmp(method,{'B1','B2','F1','F2','C2','C4'}))
      
      % NOTE: to use any of these that involve more than 1 timestep
      % forward or backward, I'll need to adjust getevents to return a
      % longer timeseries
      
      % offset vectors to compute derivatives
      Qi      = Q;
      Qim1    = [nan; Qi(1:end-1)];       % i minus 1
      Qim2    = [nan; nan; Qi(1:end-2)];  % i minus 2
      Qip1    = [Qi(2:end); nan];         % i plus 1
      Qip2    = [Qi(3:end); nan; nan];    % i plus 2
      
      Ti      = T;                        % new
      Tim1    = [nan; Ti(1:end-1)];       % i minus 1
      Tip1    = [Ti(2:end); nan];         % i plus 1
      
      % % forward, backward, and centered mean flow
      dt      = (T(2)-T(1)).*ones(size(T));
%       Qfwd    = (Qi+Qip1)./2./dt;
%       Qbwd    = (Qi+Qim1)./2./dt;
%       Qctr    = (Qip1+Qim1)./2./dt;

      % not sure why the /dt's are above, maybe before I did dqdt = dq/dt
      % at the end (since those values are the average flow over two steps)
      Qfwd    = (Qi+Qip1)./2;    
      Qbwd    = (Qi+Qim1)./2;
      Qctr    = (Qip1+Qim1)./2;

      Tbwd    = (Ti+Tim1)./2;                     % new
      Tfwd    = (Ti+Tip1)./2;
      Tctr    = (Tip1+Tim1)./2;
      
      switch method
         case 'B1'                                 % backward, version 1
            dq  = Qi-Qim1;
            q   = Qbwd;
            tq  = Tbwd;
         case 'B2'                                 % backward, version 2
            dq  = (3.*Qi-4.*Qim1+Qim2)./2;
            q   = Qbwd;
            tq  = Tbwd;
         case 'F1'                                 % forward, version 1
            dq  = Qip1-Qi;
            q   = Qfwd;
            tq  = Tfwd;
         case 'F2'                                 % forward, version 2
            dq  = (-Qip2+4.*Qip1-3.*Qi)./2;
            q   = Qfwd;
            tq  = Tfwd;
         case 'C2'                                 % centered, version 1
            dq  = (Qip1-Qim1)./2;
            q   = Qctr;
            tq  = Tctr;
         case 'C4'                                 % centered, version 2
            dq  = (-Qip2+8.*Qip1-8.*Qim1+Qip2)./12;
            q   = Qctr;
            tq  = Tctr;
      end
      dqdt = dq./dt;
      
   elseif strcmp(method,'SPN')
      
      % NOTE: this is not implemented
      
      % implement splinefit with matlab's optimal knot method
    % ord         = opts.spn.order;
      ord         = 3;
      nbreaks     = 2+fix(length(T)/4);
      breaks      = bfra_splinebreaks(T,Q,nbreaks,ord);
      pspline     = splinefit(T,Q,breaks,ord);  % piecewise cubic
      dspline     = fnder(pspline,1); % ppdiff(p_spline,1) works too
      Qspline     = ppval(pspline,T);
      dQspline    = ppval(dspline,T);
      
      q           = Qspline;
      dq          = dQspline;
      dqdt        = dQspline;
      dt          = (T(2)-T(1)).*ones(size(T));
      tq          = T;
      
   elseif strcmp(method,'SLM')
      
      % NOTE: this is not implemented
      
      ord         = spnorder;
      %nbreaks    = 2+fix(length(T1)/4);
      %breaks     = unique(bfra_splinebreaks(T1,Q1,nbreaks,ord));
      pslm        = slmengine(T,Q,'degree',ord-1,'interiorknots',   ...
                     'free','knots',100);
      dQslm       = slmeval(T,pslm,1);    % differentiate
      Qslm        = slmeval(T,pslm);      % evaluate
      q           = Qslm;
      dq          = dQslm;
      dqdt        = dQslm;
      dt          = (T(2)-T(1)).*ones(size(T));
      tq          = T;
      
   elseif strcmp(method,'pchip')
      
   elseif strcmp(method,'SGO')
      
      % NOTE: this is not implemented
      
      
%       ord         = opts.sgo.order;               % polynomial filter order
%       fl          = opts.sgo.window;              % frame length
      ord         = 3;
      fl          = 7;
      dt          = (T(2)-T(1));                  % time discretization
      Qsgolay     = sgolayfilt(Q,ord,fl);
      dQsgolay    = movingslope(Qsgolay,fl,ord,dt);
      q           = Qsgolay;
      dq          = dQsgolay;
      dqdt        = dQsgolay;
      dt          = (T(2)-T(1)).*ones(size(T));
      tq          = T;
   end
   
end