function [aQbstr,Qtstr] = aQbString(varargin)
   %AQBSTRING Return a formatted string for equation aQ^b.
   %
   % Syntax
   %
   %     [aQbstr, Qtstr] = baseflow.aQbString(ab)
   %     [aQbstr, Qtstr] = baseflow.aQbString(ab, Q0)
   %     [aQbstr, Qtstr] = baseflow.aQbString(_, 'printvalues', true)
   %
   % Description
   %
   %     [aQbstr,Qtstr] = baseflow.aQbString(ab, Q0) returns latex strings
   %     for the recession equation -dQ/dt = aQ^b and the Q(t) solution.
   %     When 'printvalues' is true, the strings include the values of the
   %     optional inputs ab = [a b] and the initial flow Q0. Otherwise the
   %     strings contain symbols only.
   %
   % Optional inputs
   %
   %     one input: array [a,b]
   %     two input: array [a,b], scalar Q0
   %     'printvalues': logical, true includes the values of ab and Q0 in
   %     the strings. The default is false.
   %
   % Output
   %
   %     aQbstr: formatted latex string for equation dQdt = aQb
   %     Qtstr: formatted latex string for equation Q(t) = f(a,b,Q0)
   %
   % Example
   %
   % % large number
   % a = 1250;
   % b = 2;
   % baseflow.aQbString([a, b], "printvalues",true)
   %
   % Also return Q(t) with a value for Q0:
   %
   % [~, Qtstr] = baseflow.aQbString([a, b], 1000, "printvalues",true)
   %
   % % Compare with sprintf
   % aexp = floor(log10(a));
   % abase = a*10^-aexp;
   % sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
   %
   % % small number
   % a = 0.001250;
   % baseflow.aQbString([a, b], "printvalues",true)
   %
   % % Compare with sprintf
   % aexp = floor(log10(a));
   % abase = a*10^-aexp;
   % sprintf('-dQ/dt = %.f$e^{%.f}Q^{%.2f}$',abase,aexp,2);
   %
   % See also: baseflow.getstring, baseflow.Qnonlin, baseflow.QtauString,
   % baseflow.QtString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % parse inputs
   [ab, Q0, printvalues] = parseinputs(mfilename, varargin{:});

   % main function. Each helper builds its own labels with values by design.
   % baseflow.getstring holds the symbolic labels.
   if printvalues == true

      % build the aQb string
      aexp = floor(log10(ab(1)));
      abase = ab(1) * 10 ^ -aexp;

      % 5/6/2022 moved $ from after = to after .fe so e is not italic
      aQbstr = sprintf('-d$Q$/d$t$ = %.fe$^{%.f}Q^{%.2f}$', ...
         abase, aexp, ab(2));

      % build the Q(t) string. This formats Q0 as an integer (%d).
      if isempty(Q0)
         Q0str = 'Q_0';
      else
         Q0str = sprintf('%d', Q0);
      end
      Qtstr = sprintf('$Q(t) = [%s^{-(b-1)}+a(b-1)t]^{-1/(b-1)} (b=%.2f)$', ...
         Q0str, ab(2));
   else
      % get the symbolic labels from baseflow.getstring so the helpers match
      aQbstr = baseflow.getstring('aQb');
      Qtstr = baseflow.getstring('Q(t)');
   end

   % convert to tex because Octave does not support the latex interpreter
   if isoctave
      aQbstr = latex2tex(aQbstr);
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
