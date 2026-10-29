function Fnc = getfunction(funcname)
   %GETFUNCTION get function handle from the baseflow function library
   %
   % Syntax
   %
   %     Fnc = getfunction(funcname)
   %
   % Description
   %
   %     Fnc = baseflow.getfunction('SofabQ') returns anonymous function handle
   %     for storage function S(a,b,Q) = (1/(a*(2-b)))*Q^(2-b)
   %
   %     Fnc = baseflow.getfunction('expectedQ') returns anonymous function
   %     handle for expected value of baseflow function Q(Q0,b) = Q0*(2-b)/(3-b)
   %
   %     Fnc = baseflow.getfunction('expectedTau') returns a function handle
   %     for the mean tau, tau(tau0,b) = tau0*(2-b)/(3-2*b). The mean diverges
   %     at the tau pole b = 3/2 (alpha = 2) and beyond, so the handle returns
   %     Inf there. It returns NaN where no Pareto tail exists (b < 1 or
   %     b >= 2). The 'expectedTime' handle, tau0/(3-2*b), shares that pole.
   %
   %     Use tab-completion to see full list of options
   %
   % See also: baseflow.getstring
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   switch funcname
      case 'SofabQ'
         Fnc = @(a,b,Q) (1./(a.*(2-b))).*Q.^(2-b);
      case 'tauofabQ'
         Fnc = @(a,b,Q) (1./a).*Q.^(1-b);
      case 'tauofabQ0'
         Fnc = @(a,b,Q0) (1./a).*Q0.^(1-b);
      case 'Qofabtau'
         Fnc = @(a,b,tau) (a.*tau).^(1./(1-b));
      case 'expectedQ'
         Fnc = @(Q0,b) Q0.*(2-b)./(3-b);  % expected value of Q
      case 'expectedTau'
         Fnc = @expectedtau;  % expected value of tau
      case 'expectedTime'
         % expected duration of baseflow, tau0/(3-2*b), with the tau pole
         Fnc = @(tau0,b) expectedtau(tau0,b)./(2-b);
      case 'boftautau0'
         Fnc = @(tau,tau0) (2.*(tau-tau0)+tau)./(2.*(tau-tau0)+tau0);
      case 'aofa0'
         Fnc = @(a0,b,tau,tau0) (1./tau).*(sqrt(a0.*tau0).*(b-3)./(b-2)).^(b-1);
   end
end
