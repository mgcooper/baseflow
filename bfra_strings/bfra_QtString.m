function [Qtstr,aQbstr] = bfra_QtString(varargin)
%BFRA_QTSTRING
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% input handling
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p = MipInputParser;
   p.FunctionName = 'bfra_QtString';
   p.addOptional('ab',[],@(x)isnumeric(x));
   p.addOptional('Q0',[],@(x)isnumeric(x));
   p.addParameter('printvalues',false,@(x)islogical(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
   
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
   
  