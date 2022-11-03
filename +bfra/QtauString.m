function [Qtaustr,aQbstr] = QtauString(varargin)
%BFRA.QTAUSTRING
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% input handling
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   p = MipInputParser;
   p.addOptional('ab',[],@(x)isnumeric(x));
   p.addOptional('tau0',[],@(x)isnumeric(x));
   p.addParameter('printvalues',false,@(x)islogical(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
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
   
   
   
