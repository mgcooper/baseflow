function [Qtstr,aQbstr] = QtString(varargin)
   %QTSTRING Return latex-formatted string for Q(t) function.
   %
   %
   % See also: Qnonlin, QtauString, aQbString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [ab, Q0, printvalues] = parseinputs(mfilename, varargin{:});

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
      % this is same as bfra.getstring
      aQbstr = bfra.getstring('aQb');
      Qtstr = bfra.getstring('Q(t)');
   end
end

%% INPUT PARSER
function [ab, Q0, printvalues] = parseinputs(mfilename, varargin)

   parser = inputParser;
   parser.FunctionName = ['bfra.' mfilename];
   parser.addOptional('ab', [], @isnumeric);
   parser.addOptional('Q0', [], @isnumeric);
   parser.addParameter('printvalues', false, @islogical);
   parser.parse(varargin{:});

   ab = parser.Results.ab;
   Q0 = parser.Results.Q0;
   printvalues = parser.Results.printvalues;
end
