function str = getstring(request, varargin)
   %GETSTRING Get latex-formatted string for equations in the baseflow library.
   %
   % Syntax
   %
   %     str = getstring(request, Name, Value)
   %
   % Description
   %
   %     str = getstring(request) returns a latex-formatted string for
   %     the requested equation or variable.
   %
   %     str = getstring(request, 'units', true) returns a latex-formatted
   %     string for the requested equation or variable with units. The default
   %     value for 'units' is false.
   %
   % Input Arguments
   %
   %     request - String specifying the desired equation or variable.
   %
   %     Name-Value Pair Arguments (Optional)
   %
   %     'units' - A logical value indicating whether to include units in the
   %               returned string. Default is false.
   %
   %     'interpreter' - A string specifying the interpreter for the output
   %                     string. Valid options are 'tex' (default) and 'latex'.
   %
   % Output
   %
   %     str - A latex-formatted string representing the requested equation or
   %           variable, possibly with units.
   %
   % Allowed Values for 'request'
   %
   %     The following strings are allowed as input for the 'request' parameter:
   %
   %     - 'Q'
   %     - 't'
   %     - 'dQdt', 'dqdt', 'dq/dt', 'dQ/dt'
   %     - 'd2Qdt', 'd2Qdt2', 'dq2/dt', 'dq2/dt2'
   %     - 'dndt', 'dn/dt'
   %     - 'dSdt', 'dS/dt'
   %     - 'aQb'
   %     - 'Q(t)', 'q(t)'
   %     - 'tau', 'Tau'
   %     - 'R', 'Rainfall'
   %
   % Examples
   %
   %     str = getstring('Q', 'units', true)
   %     % Returns: '$Q \quad [\mathrm{m}^3 \;\mathrm{d}^{-1}]$'
   %
   % See also bfra.aQbString
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % parse inputs
   [request, units, interpreter] = parseinputs(request, varargin{:});

   % main function
   if units == true
      str = getStringWithUnits(request);
   else
      str = getStringWithoutUnits(request);
   end

   % convert to tex
   switch interpreter
      case 'tex'
         str = latex2tex(str);
      case 'latex'

      otherwise
         error('unrecognized interpreter')
   end
end

%% subfunctions
function str = getStringWithUnits(request)

   switch request
      case 'Q'
         str = '$Q \quad [\mathrm{m}^3 \;\mathrm{d}^{-1}]$';
         
      case 't'
         str = '$t \quad [d]$';

      case {'dQdt','dqdt','dq/dt','dQ/dt'}
         str = [ '$-\mathrm{d}Q/\mathrm{d}t \quad[\mathrm{m}^3\;' ...
            '\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];

      case {'d2Qdt','d2Qdt2','dq2/dt','dq2/dt2'}
         str = [ '$-\mathrm{d}^2Q/\mathrm{d}t^2 \quad[\mathrm{m}^3\;' ...
            '\mathrm{d}^{-1}\;\mathrm{d}^{-2}]$'];

      case 'R'
         str = 'Rainfall $\quad [\mathrm{mm} \;\mathrm{d}^{-1}]$';
         % this might be simpler need to compare
         % str = 'Rainfall [mm d$^{-1}$]';

      case {'dndt','dn/dt'}
         str = [ '$\mathrm{d}\eta/\mathrm{d}t \quad[\mathrm{cm}\;' ...
            '\mathrm{a}^{-1}]$'];

      case {'dSdt','dS/dt'}
         str = [ '$\mathrm{d}S/\mathrm{d}t \quad[\mathrm{cm}\;' ...
            '\mathrm{a}^{-1}]$'];

      case 'aQb'
         str = ['$-\mathrm{d}Q/\mathrm{d}t$ = aQ$^b'                    ...
            '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];

      case {'Q(t)','q(t)'}
         str = ['$Q = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)}'                ...
            '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}]$'];

      case {'tau','Tau'}
         str = '$\tau \quad$ [days]';
   end
end

%%
function str = getStringWithoutUnits(request)

   switch request
      case 'Q'
         str = '$Q$';
         
      case 't'
         str = '$t$';

      case {'dQdt','dqdt','dq/dt','dQ/dt'}
         str = '$-\mathrm{d}Q/\mathrm{d}t$';

      case {'d2Qdt','d2Qdt2','dq2/dt','dq2/dt2'}
         str = '$-\mathrm{d}^2Q/\mathrm{d}t^2$';

      case {'dndt','dn/dt'}
         str = '$\mathrm{d}\eta/\mathrm{d}t$';

      case {'dSdt','dS/dt'}
         str = '$\mathrm{d}S/\mathrm{d}t$';

      case 'aQb'
         str = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';

      case {'Q(t)','q(t)'}
         str = '$Q = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)}$';
         %str = '$Q(t) = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)}$';

      case {'tau','Tau'}
         str = '$\tau$';

      case {'R','Rainfall'}
         str = 'Rainfall';
   end
end

%% Input Parser
function [request, units, interpreter] = parseinputs(request, varargin)
   parser = inputParser;
   parser.FunctionName = 'bfra.getstring';
   parser.CaseSensitive = false;
   parser.addRequired('request', @ischar);
   parser.addParameter('units', false, @islogical);
   parser.addParameter('interpreter', 'latex', @ischar);
   parser.parse(request, varargin{:});
   units = parser.Results.units;
   interpreter = parser.Results.interpreter;

   if isoctave
      interpreter = 'tex';
   end
end
