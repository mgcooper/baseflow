function [aQbstr,Qtstr] = bfra_aQbString(varargin)
%BFRA_AQBSTRING
%
% INPUTS:
   % one input:      array [a,b]
   % two input:      scalars a,b
   % three inputs:   scalars a,b,Q0
% OUTPUTS:
   % aQbstr:         formatted latex string for equation dQdt = aQb
   % Qtstr:          formatted latex string for equation Q(t) = f(a,b,Q0)

% TODO: merge this with bfra_strings

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% input handling
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p = MipInputParser;
p.FunctionName = 'bfra_aQbString';
p.addOptional('ab',[],@(x)isnumeric(x));
p.addOptional('Q0',[],@(x)isnumeric(x));
p.addParameter('printvalues',false,@(x)islogical(x));
p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   if printvalues == true
      
      aexp    = floor(log10(ab(1)));
      abase   = ab(1)*10^-aexp;
      
      % 5/6/2022 moved $ from after = to after .fe so e is not italic
      aQbstr  = sprintf('-d$Q$/d$t$ = %.fe$^{%.f}Q^{%.2f}$',abase,aexp,ab(2));
   
      if isempty(Q0)
        Qtstr = sprintf('$Q = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',ab(2));
      else
        Qtstr = sprintf('$Q = [%d^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',Q0,ab(2));
      end
      
   else
      
      aQbstr  = '-d$Q$/d$t = aQ^b$';
      
      if isempty(Q0)
        Qtstr = sprintf('$Q = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',ab(2));
      else
        Qtstr = sprintf('$Q = [%d^{-(b-1)}+at(b-1)]^{-1/(b-1)} (b=%.2f)$',Q0,ab(2));
      end
   end

%     a       = 1250;
%     aexp    = floor(log10(a));
%     abase   = a*10^-aexp;
%     sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
%     
%     a       = 0.001250;
%     aexp    = floor(log10(a));
%     abase   = a*10^-aexp;
%     sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
    
    
    
    
    
    
    