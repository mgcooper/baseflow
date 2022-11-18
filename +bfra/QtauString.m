function [Qtaustr,aQbstr] = QtauString(varargin)
%QTAUSTRING returns latex-formatted string for Q(tau) function


% input handling
%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.QtauString';

addOptional(p, 'ab',             [],      @(x)isnumeric(x));
addOptional(p, 'tau0',           [],      @(x)isnumeric(x));
addParameter(p,'printvalues',   false,   @(x)islogical(x));

parse(p,varargin{:});

ab          = p.Results.ab;
tau0        = p.Results.tau0;
printvalues = p.Results.printvalues;
%-------------------------------------------------------------------------------

if printvalues == true
   
   % build the aQb string
   aexp    = floor(log10(ab(1)));
   abase   = ab(1)*10^abs(aexp);
   aQbstr  = sprintf('-d$Q$/d$t = %.fe^{%.f}Q^{%.2f}$',abase,aexp,ab(2));
   
   % build the Q(tau) string
   if isempty(tau0)
      Qtaustr = sprintf('$Q^* = [\\tau$/$\\tau_0$]$^{-\\alpha}$ $(b=%.2f)$',ab(2));
   else
      Qtaustr = sprintf('$Q^* = [\\tau$/%d]$^{-\\alpha}$ $(b=%.2f)$',tau0,ab(2));
   end
   
else
   
   aQbstr  = '-d$Q$/d$t = aQ^b$';
   Qtaustr = '$Q^* = [\tau$/$\tau_0$]$^{-\alpha}$';
end


%    printvalues  = false;
%    Q0 = nan;
%    if nargin == 1
%       ab  = varargin{1};
%    elseif nargin == 2
%       ab  = [varargin{1};varargin{2}];
%    elseif nargin == 3
%       ab  = [varargin{1};varargin{2}];
%       Q0  = varargin{3};
%    elseif nargin == 4
%       ab  = [varargin{1};varargin{2}];
%       Q0  = varargin{3};
%       printvalues = varargin{4};
%    end   
