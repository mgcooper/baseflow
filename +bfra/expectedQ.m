function [Qexp,Q0,pQexp,pQ0] = expectedQ(a,b,tau,q,dqdt,tau0,varargin)
%EXPECTEDQ general description of function
% 
% Syntax:
% 
%  [Qexp,Q0] = bfra.EXPECTEDQ(a,b,tau);
%  [Qexp,Q0] = bfra.EXPECTEDQ(a,b,tau,'pctls',Q) returns the percentiles of
%              Qexp/Q0 relative to the input Q
% 
% Author: Matt Cooper, DD-MMM-YYYY, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'bfra.expectedQ';
validopt          = @(x)any(validatestring(x,{'qtls','plotfit'}));

addRequired(p,    'a',                    @(x)isnumeric(x)     );
addRequired(p,    'b',                    @(x)isnumeric(x)     );
addRequired(p,    'tau',                  @(x)isnumeric(x)     );
addRequired(p,    'q',                    @(x)isnumeric(x)     );
addRequired(p,    'dqdt',                 @(x)isnumeric(x)     );
addRequired(p,    'tau0',                 @(x)isnumeric(x)     );
addOptional(p,    'qtls',     '',         validopt             );
addOptional(p,    'flow',     nan,        @(x)isnumeric(x)     );
addOptional(p,    'plotfit',  '',         validopt             );
addParameter(p,   'mask',     false,      @(x)islogical(x)     );

parse(p,a,b,tau,q,dqdt,tau0,varargin{:});

qtls     = p.Results.qtls;
flow     = p.Results.flow;
plotfit  = p.Results.plotfit;
mask     = p.Results.mask;

%------------------------------------------------------------------------------

Qexp  = (a*tau)^(1/(1-b));
Q0    = Qexp*(3-b)/(2-b);

if strcmp(plotfit,'plotfit')
   plotfit = true;
else
   plotfit = false;
end

if ~isempty(qtls)
   u     = 'm$^3$ d$^{-1}$';
   fdc   = fdcurve(flow(flow>0),'refpoints',[Q0 Qexp],'units',u,'plotcurve',plotfit);
   pQ0   = fdc.fref(1);
   pQexp = fdc.fref(2);
else
   pQexp = nan;
   pQ0 = nan;
end


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% %  below here various ways of computing Q0/Qexp

% [Q0 Qexp] % 9.1069e+05   3.6818e+05
% 
% plot([Q0 Q0],ylim,'Color','r')
% plot([Qexp Qexp],ylim,'Color','r')
% 
% % given the Q0 just computed, does tau0 = Q0^(1-b2)/a2 = tau0? Nope
% % Q0^(1-b2)/a2 % these first two are equal
% % Q0^(1-b1)/a1
% % Q0^(1-b1)/a2 % 
% % Q0^(1-b2)/a1
% % Q0 = a2*tau0)
% 
% % if we believe that tau0 is the onset of recession at which time a=a1 and b=b1
% % where b1=3 and a1 is the early-time fit, then tau0 = Q0^(1-b1)/a1:
% b1    = 3;
% b2    = b;
% a1    = bfra.pointcloudintercept(q,dqdt,b1,'envelope','refqtls',[0.95 0.95]);
% Q0    = (a1*tau0)^(1/(1-b1));
% Qexp  = Q0*(2-b2)/(3-b2); % could it be: Q0*(b1-2)/(3-b2);
% 
% [Q0 Qexp] % 1.3211e+07    5.341e+06
% plot([Q0 Q0],ylim,'Color','b')
% plot([Qexp Qexp],ylim,'Color','b')
% 
% % if we equate the early-time and late-time fits to get Q0
% b1 = 3;
% b2 = b;
% a1 = bfra.pointcloudintercept(q,dqdt,b1,'envelope','refqtls',[0.95 0.95]);
% a2 = bfra.pointcloudintercept(q,dqdt,b2,'envelope','refqtls',[0.5 0.5],'mask',mask);
% Q0    = (a1/a2)^(1/(b2-b1));
% Qexp  = Q0*(2-b2)/(3-b2);
% 
% [Q0 Qexp] % 1.3211e+07    5.341e+06
% plot([Q0 Q0],ylim,'Color','g')
% plot([Qexp Qexp],ylim,'Color','g')
% 
% % NOTE: this is the way I did it originally but this is the case where it can be
% % shown to only be true for b=3 therefore the version above is correct.
% % if we believe that tau0 is the onset of recession at which time a=a2 and b=b2
% % where a2 and b2 are the late-time fits, then tau0 = Q0^(1-b2)/a2:
% Q0    = (a2*tau0)^(1/(1-b2));
% Qexp  = Q0*(2-b2)/(3-b2);
% 
% [Q0 Qexp] % 2.7105e+06   1.0958e+06
% plot([Q0 Q0],ylim,'Color','k')
% plot([Qexp Qexp],ylim,'Color','k')
% 
% % need to find where I documented the issue with the original method, but
% % working through it again, if you equate 
% % (1) Q0    = (ahat*tau0)^(1/(1-bhat))
% % (2) Qexp  = (ahat*tau)^(1/(1-bhat))
% % (3) Qexp  = Q0*(2-bhat)/(3-bhat) 
% % plug rhs of (1) into Q0 on rhs of (3) and equate that to (2)
% % (4) (ahat*tau0)^(1/(1-bhat))*(2-bhat)/(3-bhat) = (ahat*tau)^(1/(1-bhat))
% % (5) (tau0/tau)^(1/(1-bhat)) = (3-bhat)/(2-bhat)
% % (6) (tau0/tau) = (3-bhat)/(2-bhat)^(1-bhat)
% % (7) tau0 = tau*(3-bhat)/(2-bhat)^(1-bhat)
% 
% % (6) implies that tau0/tau should equal ((3-b)/(2-b))^(1-b) = 0.748 ... very
% % close to the ratio I found examining the troch solutions whcih i interpret as
% % a discontinuity at b-3. It also implies we can get tau0 this way:
% % tau0 = tau*((3-b)/(2-b))^(1-b)
% % but that doesn't match tau0 from the pareto fit, so 
% 
% % BUT ... tau = tau0*(2-b)/(3-2*b) is correct 
% 
% % how about this one ...
% % Q0 = Qexp*((3-2*b)/(2-b))^(1/(1-b))
% 
% % which implies:
% % Q0/Qexp = ((3-2*b1)/(2-b1))^(1/(1-b1)) = 7.36 ...
% % Qexp/Q0 = ((2-b)/(3-2*b))^(1/(1-b)) = 0.136 ... and 1-0.136 = 0.864 which is
% % in the numerator of the late time q outflow equation 8 of troch 1993
% 
% % so 1 - Qexp/Q0 = 1 - ((2-b)/(3-2*b))^(1/(1-b)) = 0.864 ...
% 
% 
% 
