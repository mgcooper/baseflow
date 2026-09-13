function [Qtaustr,aQbstr] = QtauString(varargin)
   %QTAUSTRING Return latex-formatted string for Q(tau) function.
   %
   % Syntax
   %
   %     [Qtaustr, aQbstr] = baseflow.QtauString(ab, tau0)
   %     [Qtaustr, aQbstr] = baseflow.QtauString(_, 'printvalues', true)
   %
   % Description
   %
   %     [Qtaustr, aQbstr] = baseflow.QtauString(ab, tau0) returns latex
   %     strings for the dimensionless Q* = (tau/tau0)^-alpha function and
   %     the recession equation -dQ/dt = aQ^b. When 'printvalues' is true,
   %     the strings include the values of the optional inputs ab = [a b]
   %     and the reference time tau0. Otherwise the strings contain symbols
   %     only.
   %
   % See also: Qnonlin, QtString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [ab, tau0, printvalues] = parseinputs(mfilename, varargin{:});

   if printvalues == true
      % build the aQb string
      aexp    = floor(log10(ab(1)));
      abase   = ab(1)*10^abs(aexp);
      aQbstr  = sprintf('-d$Q$/d$t = %.fe^{%.f}Q^{%.2f}$',abase,aexp,ab(2));

      % build the Q(tau) string
      if isempty(tau0)
         Qtaustr = ...
            sprintf('$Q^* = [\\tau$/$\\tau_0$]$^{-\\alpha}$ $(b=%.2f)$',ab(2));
      else
         Qtaustr = ...
            sprintf('$Q^* = [\\tau$/%d]$^{-\\alpha}$ $(b=%.2f)$',tau0,ab(2));
      end
   else
      aQbstr  = '-d$Q$/d$t = aQ^b$';
      Qtaustr = '$Q^* = [\tau$/$\tau_0$]$^{-\alpha}$';
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