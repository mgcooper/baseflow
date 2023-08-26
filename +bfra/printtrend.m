function [ddt, err] = printtrend(Data, varargin)
%PRINTTREND print trends computed from columns in table Data to the screen
% 
%  Syntax
% 
%  [ddt,err] = printtrend(Data,varargin)
% 
% See also

% PARSE INPUTS
[Data, method, var, cf, alpha, qtl] = parseinputs(Data, varargin{:});

% create a regular time in years, works for both months and years
t = years(Data.Time-Data.Time(1)) + year(Data.Time(1));
dt = numel(t);
dat = Data.(var); % cm/yr -> cm/day

switch method
   case 'ols'
      mdl = fitlm(t,dat); 
      ddt = mdl.Coefficients.Estimate(2);  % cm/day/year
      CIs = coefCI(mdl,alpha);
      err = CIs(2,2)-ddt;
   case 'qtl'
      [ab,S] = quantreg(t,dat,qtl,1,1000,alpha);
      ddt = ab(2);
      CIs = S.ci_boot';
      err = CIs(2,2)-ddt;
end
% adjust the trend and error units using the conversion factor
ddt = cf*ddt;
d = ddt*dt;
err = cf*err;
derr = err*dt;
errstr = num2str(round(100*(1-alpha)));
str = ['\nd' var '/dt = %.3f ' char(177) ' %.3f (' errstr '%% CI) '];
str = [str ', d' var ' = %.3f ' char(177) ' %.3f \n\n'];
fprintf(str,ddt,err,d,derr);

%% PARSE INPUTS
function [Data, method, var, cf, alpha, qtl] = parseinputs(Data, varargin)
parser = inputParser;
parser.StructExpand = true; % this has to be true to use autocomplete fieldname
parser.FunctionName = 'bfra.printtrend';

parser.addRequired('Data', @istimetable);
parser.addParameter('var', 'Qb', @ischar);
parser.addParameter('alpha', 0.05, @isnumeric);
parser.addParameter('metric', 'CI', @ischar);
parser.addParameter('method', 'ols', @ischar);
parser.addParameter('quantile', nan, @isnumeric);
parser.addParameter('unitconversion', 1, @isnumeric);

parser.parse(Data, varargin{:});

cf = parser.Results.unitconversion;
var  = parser.Results.var;
qtl = parser.Results.quantile;
alpha = parser.Results.alpha;
method = parser.Results.method;

% no longer used:
% metric = parser.Results.metric;

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
