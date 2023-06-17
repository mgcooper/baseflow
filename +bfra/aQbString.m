function [aQbstr,Qtstr] = aQbString(varargin)
%AQBSTRING return a formatted string for equation aQ^b
%
% Syntax
% 
%     [aQbstr,Qtstr] = aQbString(ab) prints -dQ/dt = aQ^b
% 
% Optional inputs
% 
%     one input:      array [a,b]
%     two input:      array [a,b], scalar Q0
% 
% Output
% 
%     aQbstr:         formatted latex string for equation dQdt = aQb
%     Qtstr:          formatted latex string for equation Q(t) = f(a,b,Q0)
% 
% Example
%
% % large number
% a = 1250;
% b = 2;
% bfra.aQbString([a, b], "printvalues",true)
% bfra.aQbString(a, b, "printvalues",true)
% 
% % Compare with sprintf
% aexp    = floor(log10(a));
% abase   = a*10^-aexp;
% sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
%
% % small number
% a = 0.001250;
% bfra.aQbString([a, b], "printvalues",true)
% 
% % Compare with sprintf
% aexp    = floor(log10(a));
% abase   = a*10^-aexp;
% sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
% 
% See also getstring
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% TODO: merge this with bfra.strings. See note below about $ after = sign.


% parse inputs
[ab, Q0, printvalues] = parseinputs(varargin{:});

% main function
if printvalues == true
   
   aexp = floor(log10(ab(1)));
   abase = ab(1)*10^-aexp;
   
   % 5/6/2022 moved $ from after = to after .fe so e is not italic
   aQbstr = sprintf('-d$Q$/d$t$ = %.fe$^{%.f}Q^{%.2f}$',abase,aexp,ab(2));
   
   if isempty(Q0)
      Qtstr = sprintf('$Q = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',ab(2));
   else
      Qtstr = sprintf('$Q = [%d^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',Q0,ab(2));
   end
   
else
   
   aQbstr = '-d$Q$/d$t = aQ^b$';
   
   if isempty(Q0)
      Qtstr = sprintf('$Q = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',ab(2));
   else
      Qtstr = sprintf('$Q = [%d^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',Q0,ab(2));
   end
end

if bfra.util.isoctave
   aQbstr = bfra.util.latex2tex(aQbstr);
   Qtstr = bfra.util.latex2tex(Qtstr);
end


function [ab, Q0, printvalues] = parseinputs(varargin)

p = inputParser;
p.FunctionName = 'bfra.aQbString';
addOptional(p,'ab',[],@(x)isnumeric(x));
addOptional(p,'Q0',[],@(x)isnumeric(x));
addParameter(p,'printvalues',false,@(x)islogical(x));
parse(p,varargin{:});
ab = p.Results.ab;
Q0 = p.Results.Q0;
printvalues = p.Results.printvalues;





