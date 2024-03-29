function varargout = conversions(inputvalue,inputvarname,outputvarname,varargin)
   %CONVERSIONS convert inputvalue of inputvarname to the value of outputvarname
   %
   % Syntax
   %
   %     varargout = conversions(inputvalue,inputvarname,outputvarname,varargin)
   %
   % Description
   %
   %     outputvalue = conversions(inputvalue,inputvarname,outputvarname)
   %     converts inputvalue from its value in terms of inputvarname to its
   %     equivalent value in terms of outputvarname (use tab completion to get a
   %     list of supported input and output varnames)
   %
   %     outputvalue = conversions(inputvalue,inputvarname,outputvarname,'isflat',false)
   %     uses the sloped-aquifer solution. Default behavior is true.
   %
   % Example
   %
   %     b = 1.5;
   %     n = baseflow.conversions(b,'b','n')
   %        n = 0
   %
   %
   % See also baseflow.getstring
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [inputvalue, inputvarname, outputvarname, isflat] = parseinputs( ...
      inputvalue, inputvarname, outputvarname, varargin{:});

   % convert whatever is passed in to b, then from b to whatever is requested
   b = convert2b(inputvalue,inputvarname,isflat);
   varargout{1} = convertb(b,outputvarname,isflat);
end

%% Local Functions
function b = convert2b(inputvalue,inputvarname,isflat)
   %CONVERT2B Convert the recession flow power law exponent b to any
   %of several other recession flow parameters
   %
   %   Inputs:   alpha,    from Q ~ t*^-alpha
   %              beta,    from Q ~ S^-beta (beta = -d)
   %             gamma,    from 1/gamma = 1/alpha + 1/beta
   %                 N,    from a = c1*D^N, where c1 is a coefficient
   %             Nstar,    from N* = 1/(N+1)
   %                 d,    from Q = cS^d, where d = 1/(2-b)
   %                 n,    from k(z) = kD(z/D)^n,
   %                 k,    from P(Q) ~ Q^-(1+1/k)
   %            isflat,    true if flat aquifer
   %
   %  Outputs:       b,    from dQ(t)=a*Q^b

   switch inputvarname

      case 'b'
         b = inputvalue;
      case 'alpha'
         alpha = inputvalue;
         b = 1+1./alpha;
      case 'beta'
         beta = inputvalue;
         b = 2+1./beta;
      case 'gamma'
         gamma = inputvalue;
         b = 1/2.*(3+1./gamma);
      case 'd'
         d = inputvalue;
         b = 2-1./d;
      case 'k'
         k = inputvalue;
         b = (2.*k+1)./(k+1);
         %b = (k+1)./(2.*k+1);

      case 'n'
         n =  inputvalue;
         switch isflat
            case true
               b = (2.*n+3)./(n+2);
            case false
               b = (2.*n+1)./(n+1);
         end

      case 'N'
         N = inputvalue;
         switch isflat
            case true
               b = (3-N)./2;
            case false
               b = 1-N;
         end
   end
end

function varargout = convertb(b,outputvarname,isflat)
   %BCONVERSIONS Convert the recession flow power law exponent b to any of
   %several other recession flow parameters.
   %
   %  Inputs:        b,    from dQ(t)=a*Q^b
   %            isflat,    true if flat aquifer
   %
   %  Outputs:   alpha,    from P(Q) ~ t*^-alpha
   %              beta,    from Q ~ S^-beta (beta = -d)
   %             gamma,    from 1/gamma = 1/alpha + 1/beta
   %                 N,    from a = c1*D^N, where c1 is a coefficient
   %             Nstar,    from N* = 1/(N+1)
   %                 d,    from Q = cS^d, where d = 1/(2-b)
   %                 n,    from k(z) = kD(z/D)^n,
   %                 k,    from P(Q) ~ Q^-(1+1/k)

   alpha = 1./(b-1);       % power law exponent alpha
   beta  = 1./(b-2);
   gamma = 1./(2.*b-3);
   d     = 1./(2-b);
   k     = (1-b)./(b-2);   % gpd shape parameter power law exponent k
   % k     = (b-2)./(1-b);   % gpd shape parameter power law exponent k

   switch isflat
      case true
         n = (3-2.*b)./(b-2);   % saturated hyd. cond. power function exponent
         N = 3-2.*b;            % scale parameter power law exponent N
         Nstar = 1./(4-2.*b);

      case false
         n = (1-b)./(b-2);
         N = 1-b;
         Nstar = 1./(2-b);
   end

   switch outputvarname
      case 'b'
         varargout{1} = b;
      case 'alpha'
         varargout{1} = alpha;
      case 'beta'
         varargout{1} = beta;
      case 'gamma'
         varargout{1} = gamma;
      case 'd'
         varargout{1} = d;
      case 'k'
         varargout{1} = k;
      case 'n'
         varargout{1} = n;
      case 'N'
         varargout{1} = N;
      case 'Nstar'
         varargout{1} = Nstar;
   end
end

%% INPUT PARSER
function [inputvalue, inputvarname, outputvarname, isflat] = parseinputs( ...
      inputvalue, inputvarname, outputvarname, varargin)

   validvarnames = {'b', 'alpha', 'beta', 'gamma', 'd', 'k', 'n', 'N', 'Nstar'};

   parser = inputParser;
   parser.FunctionName = 'baseflow.conversions';

   parser.addRequired('inputvalue', @isnumeric);
   parser.addRequired('inputvarname', @(x) ~isempty(validatestring(x, validvarnames)));
   parser.addRequired('outputvarname', @(x) ~isempty(validatestring(x, validvarnames)));
   parser.addParameter('isflat', true, @islogical);

   parser.parse(inputvalue, inputvarname, outputvarname, varargin{:});

   inputvalue = parser.Results.inputvalue;
   inputvarname = parser.Results.inputvarname;
   outputvarname = parser.Results.outputvarname;
   isflat = parser.Results.isflat;
end
