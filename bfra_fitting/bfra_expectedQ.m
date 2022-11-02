function [Qexp,Q0,pQexp,pQ0] = bfra_expectedQ(a,b,tau,varargin)
%BFRA_EXPECTEDQ general description of function
% 
% Syntax:
% 
%  [Qexp,Q0] = BFRA_EXPECTEDQ(a,b,tau);
%  [Qexp,Q0] = BFRA_EXPECTEDQ(a,b,tau,'pctls',Q) returns the percentiles of
%              Qexp/Q0 relative to the input Q
% 
% Author: Matt Cooper, DD-MMM-YYYY, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'bfra_expectedQ';

addRequired(p,    'a',                    @(x)isnumeric(x)     );
addRequired(p,    'b',                    @(x)isnumeric(x)     );
addRequired(p,    'tau',                  @(x)isnumeric(x)     );
addOptional(p,    'pctls',    '',         @(x)ischar(x)        );
addOptional(p,    'Q',        nan,        @(x)isnumeric(x)     );
addOptional(p,    'plotfit',  '',         @(x)ischar(x)        );

parse(p,a,b,tau,varargin{:});

pctls    = p.Results.pctls;
Q        = p.Results.Q;
plotfit  = p.Results.plotfit;

%------------------------------------------------------------------------------

Qexp  = (a*tau)^(1/(1-b));
Q0    = Qexp*(3-b)/(2-b);

if strcmp(plotfit,'plotfit')
   plotfit = true;
else
   plotfit = false;
end

if ~isempty(pctls)
   u     = 'm$^3$ d$^{-1}$';
   fdc   = fdcurve(Q(Q>0),'refpoints',[Q0 Qexp],'units',u,'plotcurve',plotfit);
   pQ0   = fdc.fref(1);
   pQexp = fdc.fref(2);
else
   pQexp = nan;
   pQ0 = nan;
end












