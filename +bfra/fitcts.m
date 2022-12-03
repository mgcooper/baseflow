function [q,dqdt,dt,tq,rq,dq] = fitcts(T,Q,R,varargin) 
%FITCTS fit q/dqdt using constant time step. not implemented.
%


% NOTE: to use any of these that involve more than 1 timestep
% forward or backward, I'll need to adjust findevents to return a
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
% Qfwd    = (Qi+Qip1)./2./dt;
% Qbwd    = (Qi+Qim1)./2./dt;
% Qctr    = (Qip1+Qim1)./2./dt;

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
