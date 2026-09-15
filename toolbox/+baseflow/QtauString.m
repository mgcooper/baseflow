function Qtaustr = QtauString(varargin)
   %QTAUSTRING Return latex-formatted string for Q(tau) function.
   %
   % Syntax
   %
   %     Qtaustr = baseflow.QtauString(ab)
   %     Qtaustr = baseflow.QtauString(ab, tau0)
   %     Qtaustr = baseflow.QtauString(_, 'printvalues', true)
   %
   % Description
   %
   %     Qtaustr = baseflow.QtauString(ab, tau0) returns a latex string for
   %     the dimensionless Q* = (tau/tau0)^-alpha function. When
   %     'printvalues' is true, the string includes the value of b from the
   %     optional input ab = [a b] and the reference time tau0. Otherwise
   %     the string contains symbols only.
   %
   % Optional inputs
   %
   %     one input: array [a,b]
   %     two input: array [a,b], scalar tau0
   %     'printvalues': logical, true includes the values of b and tau0 in
   %     the string. The default is false.
   %
   % Output
   %
   %     Qtaustr: formatted latex string for equation Q* = f(tau,tau0,alpha)
   %
   % Example
   %
   % a = 1250;
   % b = 2;
   % baseflow.QtauString([a, b], "printvalues",true)
   %
   % Include a value for tau0:
   %
   % Qtaustr = baseflow.QtauString([a, b], 5, "printvalues",true)
   %
   % See also: baseflow.getstring, baseflow.Qnonlin, baseflow.QtString,
   % baseflow.aQbString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % parse inputs
   [ab, tau0, printvalues] = parseinputs(mfilename, varargin{:});

   % main function. Each helper builds its own label with values by design.
   % baseflow.getstring holds the symbolic labels.
   if printvalues == true

      % build the Q(tau) string. This formats tau0 as an integer (%d).
      if isempty(tau0)
         tau0str = '$\tau_0$';
      else
         tau0str = sprintf('%d', tau0);
      end
      Qtaustr = sprintf('$Q^* = [\\tau$/%s]$^{-\\alpha}$ $(b=%.2f)$', ...
         tau0str, ab(2));
   else
      % use the symbolic Q* label here because getstring has no Q* label
      Qtaustr = '$Q^* = [\tau$/$\tau_0$]$^{-\alpha}$';
   end

   % convert to tex because Octave does not support the latex interpreter
   if isoctave
      Qtaustr = latex2tex(Qtaustr);
   end
end

%% INPUT PARSER
function [ab, tau0, printvalues] = parseinputs(mfilename, varargin)

   parser = inputParser;
   parser.FunctionName = ['baseflow.' mfilename];
   parser.addOptional('ab', [], @isnumeric);
   parser.addOptional('tau0', [], @isnumeric);
   parser.addParameter('printvalues', false, @islogical);
   parser.parse(varargin{:});

   ab = parser.Results.ab;
   tau0 = parser.Results.tau0;
   printvalues = parser.Results.printvalues;

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

end
