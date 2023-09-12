function [phi, a] = eventphi(Results, Fits, A, D, L, blate, varargin)
   %EVENTPHI estimate drainable porosity phi from individual recession events
   %
   % Syntax
   %
   %     [phi,a] = eventphi(Results,Fits,A,D,L,blate)
   %     [phi,a] = eventphi(_,'earlyqtls',[0.95 0.95])
   %     [phi,a] = eventphi(_,'lateqtls',[0.5 0.5])
   %     [phi,a] = eventphi(_,'soln1', SOLN1)
   %     [phi,a] = eventphi(_,'soln2', SOLN2)
   %
   % Description
   %
   %     Uses the method of Troch, Troch, and Brutsaert, 1993 to compute
   %     drainable porosity from early-time and late-time recession parameters
   %     and aquifer properties area A, depth D, and channel lenght L.
   %
   % Required inputs
   %
   %     Results  Table of a, b, tau, values for each event (output of fitevents)
   %     Fits     Struct containing the fitted q/dqdt timeseries (output of baseflow.dqdt)
   %     A        Numeric scalar, basin area contributing to baseflow (L^2)
   %     D        Numeric scalar, saturated aquifer thickness (L)
   %     L        Numeric scalar, active stream length (L)
   %     blate    Numeric scalar, late-time b parameter in -dqdt = aq^b (dimensionless)
   %
   % Optional name-value inputs
   %
   %     lateqtls    Quantiles of Q and -dQ/dt on point cloud through which
   %                 late-time line is forced to pass through.
   %     earlyqtls   Quantiles of Q and -dQ/dt on point cloud through which
   %                 early-time line is forced to pass through.
   %     theta       Effective slope of basin contributing area.
   %     isflat      Logical scalar indicating horizontal or sloped aquifer
   %                 solution.
   %     soln1       String indicating early-time theoretical solution.
   %     soln2       String indicating late-time theoretical solution.
   %
   % See also: cloudphi, fitphi, fitdistphi
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % If called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [Results, Fits, A, D, L, b2, earlyqtls, lateqtls, soln1, soln2] = ...
      parseinputs(Results, Fits, A, D, L, blate, varargin{:});

   % warning off % commented out for octave, need msgid

   % Take out the data and initialize the output.
   b1 = 3;
   q = Fits.q;
   dqdt = Fits.dqdt;
   tags = Fits.eventTags;
   
   N = numel(Results.eventTag);
   a = nan(N, 1);
   phi = nan(N, 1);

   % Loop over all events and compute drainable porosity (phi).
   for n = 1:N

      ifit = tags == Results.eventTag(n);
      thisq = q(ifit);
      thisdqdt = dqdt(ifit);

      if isempty(thisq) || isempty(thisdqdt)
         continue;
      end

      % Put a line of slope 3 and 1/1.5/bhat through the point cloud
      a1 = baseflow.pointcloudintercept(thisq, thisdqdt, b1, 'envelope', ...
         'refqtls', earlyqtls);
      a2 = baseflow.pointcloudintercept(thisq, thisdqdt, b2, 'envelope', ...
         'refqtls', lateqtls);

      % Choose appropriate solutions
      if isempty(soln1) && isempty(soln2)

         if b2 == 1
            phi(n) = baseflow.fitphi(a1,a2,b2,A,D,L,'isflat',true, ...
               'soln1','PK62','soln2','BS03');
         elseif b2 == 3/2
            phi(n) = baseflow.fitphi(a1,a2,b2,A,D,L,'isflat',true, ...
               'soln1','PK62','soln2','BS04');
         elseif b2>1 && b2<2
            phi(n) = baseflow.fitphi(a1,a2,b2,A,D,L,'isflat',true, ...
               'soln1','RS05','soln2','RS05');
         else
            % phi remains nan
         end
         % user-specified solutions
      else
         phi(n) = baseflow.fitphi(a1,a2,b2,A,D,L,'isflat',true,             ...
            'soln1',soln1,'soln2',soln2);
      end
      a(n) = a2;
   end
   % warning on % commented out for octave, need msgid
end

%% INPUT PARSER
function [Results, Fits, A, D, L, b2, earlyqtls, lateqtls, soln1, soln2] = ...
      parseinputs(Results, Fits, A, D, L, b2, varargin)

   parser = inputParser;
   parser.FunctionName = 'baseflow.eventphi';
   parser.StructExpand = false;
   parser.addRequired('Results', @isstruct);
   parser.addRequired('Fits', @isstruct);
   parser.addRequired('A', @isnumeric);
   parser.addRequired('D', @isnumeric);
   parser.addRequired('L', @isnumeric);
   parser.addRequired('blate', @isnumeric);
   parser.addParameter('earlyqtls', [0.95 0.95], @isnumeric);
   parser.addParameter('lateqtls', [0.5 0.5], @isnumeric);
   parser.addParameter('soln1', '', @ischar);
   parser.addParameter('soln2', '', @ischar);

   parser.parse(Results, Fits, A, D, L, b2, varargin{:});

   Results = parser.Results.Results;
   A = parser.Results.A;
   D = parser.Results.D;
   L = parser.Results.L;
   b2 = parser.Results.blate;
   Fits = parser.Results.Fits;
   soln1 = parser.Results.soln1;
   soln2 = parser.Results.soln2;
   lateqtls = parser.Results.lateqtls;
   earlyqtls = parser.Results.earlyqtls;

   % % No longer supported
   % parser.addParameter('method', 'envelope', @ischar);
   % parser.addParameter('theta', 0, @isnumeric);
   % parser.addParameter('isflat', true, @islogical);
   % theta = parser.Results.theta;
   % method = parser.Results.method;
   % isflat = parser.Results.isflat;
end
