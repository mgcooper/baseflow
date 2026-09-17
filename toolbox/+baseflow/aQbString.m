function aQbstr = aQbString(varargin)
   %AQBSTRING Return a formatted string for equation aQ^b.
   %
   % Syntax
   %
   %     aQbstr = baseflow.aQbString(ab)
   %     aQbstr = baseflow.aQbString(_, 'printvalues', true)
   %
   % Description
   %
   %     aQbstr = baseflow.aQbString(ab) returns a latex string for the
   %     recession equation -dQ/dt = aQ^b. When 'printvalues' is true, the
   %     string includes the values of the optional input ab = [a b].
   %     Otherwise the string contains symbols only.
   %
   % Optional inputs
   %
   %     one input: array [a,b]
   %     'printvalues': logical, true includes the values of ab in the
   %     string. The default is false.
   %
   % Output
   %
   %     aQbstr: formatted latex string for equation dQdt = aQb
   %
   % Example
   %
   % % large number
   % a = 1250;
   % b = 2;
   % baseflow.aQbString([a, b], "printvalues",true)
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
   [ab, printvalues] = parseinputs(mfilename, varargin{:});

   % main function. Each helper builds its own label with values by design.
   % baseflow.getstring holds the symbolic labels.
   if printvalues == true

      % build the aQb string
      aexp = floor(log10(ab(1)));
      abase = ab(1) * 10 ^ -aexp;

      % 5/6/2022 moved $ from after = to after .fe so e is not italic
      aQbstr = sprintf('-d$Q$/d$t$ = %.fe$^{%.f}Q^{%.2f}$', ...
         abase, aexp, ab(2));
   else
      % get the symbolic label from baseflow.getstring so the helpers match
      aQbstr = baseflow.getstring('aQb');
   end

   % convert to tex because Octave does not support the latex interpreter
   if isoctave
      aQbstr = latex2tex(aQbstr);
   end
end

%% INPUT PARSER
function [ab, printvalues] = parseinputs(mfilename, varargin)

   parser = inputParser;
   parser.FunctionName = ['baseflow.' mfilename];
   parser.addOptional('ab', [], @isnumeric);
   parser.addParameter('printvalues', false, @islogical);
   parser.parse(varargin{:});

   ab = parser.Results.ab;
   printvalues = parser.Results.printvalues;

end
