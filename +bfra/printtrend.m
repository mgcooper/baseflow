function [ddt,err] = printtrend(Data,varargin)
%PRINTTREND print trends computed from columns in table Data to the screen
% 
%  Syntax
% 
%  [ddt,err] = printtrend(Data,varargin)
% 
% See also

%-------------------------------------------------------------------------------
p              = magicParser;
p.StructExpand = true;  % this has to be true to use autocomplete fieldname
p.FunctionName = 'printtrend';

p.addRequired(    'Data',                    @(x)istimetable(x));
p.addParameter(   'var',            'Qb',    @(x)ischar(x));
p.addParameter(   'alpha',          0.05,    @(x)isnumeric(x));
p.addParameter(   'unitconversion', 1,       @(x)isnumeric(x));
p.addParameter(   'metric',         'CI',    @(x)ischar(x));
p.addParameter(   'method',         'ols',   @(x)ischar(x));
p.addParameter(   'quantile',       nan,     @(x)isnumeric(x));

p.parseMagically('caller');

var   = p.Results.var;
cf    = p.Results.unitconversion;
alpha = p.Results.alpha;
qtl   = p.Results.quantile;

%-------------------------------------------------------------------------------
% create a regular time in years, works for both months and years

t        = years(Data.Time-Data.Time(1)) + year(Data.Time(1));
dat      = Data.(var);                    % cm/yr -> cm/day
dt       = numel(t);
switch method
   case 'ols'
      mdl      = fitlm(t,dat); 
      ddt      = mdl.Coefficients.Estimate(2);  % cm/day/year
      CI       = coefCI(mdl,alpha);
      err      = CI(2,2)-ddt;
   case 'qtl'
      [ab,S]   = quantreg(t,dat,qtl,1,1000,alpha);
      ddt      = ab(2);
      CI       = S.ci_boot';
      err      = CI(2,2)-ddt;
end
% adjust the trend and error units using the conversion factor
ddt      = cf*ddt;
d        = ddt*dt;
err      = cf*err;
derr     = err*dt;
errstr   = num2str(round(100*(1-alpha)));
str      = ['\nd' var '/dt = %.3f ' char(177) ' %.3f (' errstr '%% CI) '];
str      = [str ', d' var ' = %.3f ' char(177) ' %.3f \n\n'];
fprintf(str,ddt,err,d,derr);

%    if alpha == 0.05 || alpha == 0.95
%       metric   = 'CI';
%       err      = coefCI(mdl,alpha)*cf;
%       CI       = mdl.coefCI;                    % 95% CI's
%       CI       = CI(2,:);
%       CI2      = CI(2)-ddt;                     % CI half-width
%    elseif alpha == 0.32 || alpha == 0.68
%       metric = 'SE';
%       SE       = mdl.Coefficients.SE(2);        % standard error
%    else
%       metric = 'userdefined';
%    end
%    
%    switch metric
%       case 'SE'
%          fprintf(['\n d' var '/dt = %.2f ' char(177) ' %.2f (68% CI) \n'],ddt,err);
%       case 'CI'
%          fprintf(['\n dQ/dt = %.2f ' char(177) ' %.2f (95% CI) \n'],ddt*cf,CI2*cf);
%       case 'userdefined'
%          fprintf(['\n dQ/dt = %.2f ' char(177) ' %.2f (' alpha '%CI) \n'],ddt*cf,CI2*cf);
%    end
%    
%    