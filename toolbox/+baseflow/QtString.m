function Qtstr = QtString(varargin)
   %QTSTRING Return latex-formatted string for Q(t) function.
   %
   % Syntax
   %
   %     Qtstr = baseflow.QtString(ab)
   %     Qtstr = baseflow.QtString(ab, Q0)
   %     Qtstr = baseflow.QtString(_, 'printvalues', true)
   %
   % Description
   %
   %     Qtstr = baseflow.QtString(ab, Q0) returns a latex string for the
   %     Q(t) solution of the recession equation -dQ/dt = aQ^b. When
   %     'printvalues' is true, the string includes the value of b from the
   %     optional input ab = [a b] and the initial flow Q0. Otherwise the
   %     string contains symbols only.
   %
   % Optional inputs
   %
   %     one input: array [a,b]
   %     two input: array [a,b], scalar Q0
   %     'printvalues': logical, true includes the values of b and Q0 in
   %     the string. The default is false.
   %
   % Output
   %
   %     Qtstr: formatted latex string for equation Q(t) = f(a,b,Q0)
   %
   % Example
   %
   % a = 1250;
   % b = 2;
   % baseflow.QtString([a, b], "printvalues",true)
   %
   % Include a value for Q0:
   %
   % Qtstr = baseflow.QtString([a, b], 1000, "printvalues",true)
   %
   % See also: baseflow.getstring, baseflow.Qnonlin, baseflow.QtauString,
   % baseflow.aQbString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % parse inputs
   [ab, Q0, printvalues] = parseinputs(mfilename, varargin{:});

   % main function. Each helper builds its own label with values by design.
   % baseflow.getstring holds the symbolic labels.
   if printvalues == true

      % build the Q(t) string. This formats Q0 as an integer (%d).
      if isempty(Q0)
         Q0str = 'Q_0';
      else
         Q0str = sprintf('%d', Q0);
      end
      Qtstr = sprintf('$Q(t) = [%s^{-(b-1)}+a(b-1)t]^{-1/(b-1)} (b=%.2f)$', ...
         Q0str, ab(2));
   else
      % get the symbolic label from baseflow.getstring so the helpers match
      Qtstr = baseflow.getstring('Q(t)');
   end

   % convert to tex because Octave does not support the latex interpreter
   if isoctave
      Qtstr = latex2tex(Qtstr);
   end
end

%% INPUT PARSER
function [ab, Q0, printvalues] = parseinputs(mfilename, varargin)

   parser = inputParser;
   parser.FunctionName = ['baseflow.' mfilename];
   parser.addOptional('ab', [], @isnumeric);
   parser.addOptional('Q0', [], @isnumeric);
   parser.addParameter('printvalues', false, @islogical);
   parser.parse(varargin{:});

   ab = parser.Results.ab;
   Q0 = parser.Results.Q0;
   printvalues = parser.Results.printvalues;

end
