function [Qtstr,aQbstr] = QtString(varargin)
%QTSTRING returns latex-formatted string for Q(t) function


% input handling
%-------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.QtString';
addOptional('ab',             [],      @(x)isnumeric(x));
addOptional('Q0',             [],      @(x)isnumeric(x));
addParameter('printvalues',   false,   @(x)islogical(x));

parse(p,varargin{:});

ab          = p.Results.ab;
Q0          = p.Results.Q0;
printvalues = p.Results.printvalues;

%-------------------------------------------------------------------------------

% this formats Q0 as an integer (.f)

if printvalues == true
   
   % build the aQb string
   aexp    = floor(log10(ab(1)));
   abase   = ab(1)*10^abs(aexp);
   aQbstr  = sprintf('-d$Q$/d$t = %.fe^{%.f}Q^{%.2f}$',abase,aexp,ab(2));
   
   % build the Q(t) string
   if isempty(Q0)
      Qtstr = sprintf('$Q(t) = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',ab(2));
   else
      Qtstr = sprintf('$Q(t) = [%d^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',Q0,ab(2));
   end
   
else
   
   aQbstr   = '-d$Q$/d$t = aQ^b$';
   Qtstr    = '$Q(t) = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)}$';
end

