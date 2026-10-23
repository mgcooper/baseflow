function [T, Q, R, Info] = eventfinder(t, q, r, varargin)
   %EVENTFINDER find recession events using hydrograph and rainfall timeseries.
   %
   % Syntax
   %
   %     [T,Q,R,Info] = eventfinder(t,q,r)
   %     [T,Q,R,Info] = eventfinder(t,q,r,opts)
   %     [T,Q,R,Info] = eventfinder(_, 'nmin', nmin)
   %     [T,Q,R,Info] = eventfinder(_, 'fmax', fmax)
   %     [T,Q,R,Info] = eventfinder(_, 'rmax', rmax)
   %     [T,Q,R,Info] = eventfinder(_, 'rmin', rmin)
   %     [T,Q,R,Info] = eventfinder(_, 'rmrain', false)
   %     [T,Q,R,Info] = eventfinder(_, 'rmconvex', true)
   %     [T,Q,R,Info] = eventfinder(_, 'rmnochange', false)
   %     [T,Q,R,Info] = eventfinder(_, 'qerror', qerror)
   %
   % Description
   %
   %     [T,Q,R,Info] = eventfinder(t,q,r) Detects periods of declining flow on
   %     hydrographs defined by inputs time 't', discharge 'q', and rainfall
   %     'r'. Use optional inputs to set parameters that determine how events
   %     are identified.
   %
   % Required inputs
   %
   %     t           time
   %     q           flow (m3/time)
   %     r           rain (mm/time)
   %
   % Optional name-value inputs
   %
   %     opts        (optional) structure with any of the fields below. It
   %                 must not contain other fields, so a
   %                 baseflow.setopts('getevents') struct is rejected.
   %     nmin        minimum event length
   %     fmax        maximum # of missing values gap-filled
   %     rmax        maximum run of sequential constant values
   %     rmin        minimum rainfall required to censor flow (mm/day?)
   %     rmconvex    remove convex derivatives
   %     rmnochange  remove consecutive constant derivates
   %     rmrain      remove rainfall
   %     qerror      bound on the rounding error of each value of q, in the
   %                 units of q. Default u*max(abs(q)), one rounding.
   %                 getevents passes the bound that its smoothing returns.
   %
   %     Each option default except qerror is the
   %     baseflow.setopts('getevents') value. nmin must be greater than 2.
   %     rmax must be greater than 1: the rmnochange filter marks d2q/dt2
   %     values beyond the numerical-zero curvature nan. Each nan counts as
   %     a run of length 1, so an rmax of 1 or less rejects every day.
   %
   % Numerical zero
   %
   %     The filters test the sign of dq/dt and d2q/dt2, the extrema of q
   %     and dq/dt, and the trend of q and dq/dt over an event. Exact
   %     arithmetic gives a zero slope on a constant stretch and a zero
   %     curvature on a straight stretch, but computed values carry
   %     rounding, and the smoothing that getevents applies makes it
   %     depend on the MATLAB release. So each test treats a value as zero
   %     when its magnitude does not exceed the rounding error of its own
   %     computation. With u = eps/2 and s = max(abs(q)), each flow value
   %     carries at most qerror, and E1 = qerror + 2*u*s adds the rounding
   %     of one difference. A slope is zero within 2*E1 and a curvature
   %     within 4*E1, the sums of absolute weights of a first and a second
   %     difference. An extremum must rise above its neighbours by more
   %     than that amount. The 3-day moving mean adds 3*u*s. Each test
   %     compares a per-sample difference with a threshold in the same
   %     units, so the time unit does not matter. The rule scales with q,
   %     so a positive factor on q does not change the events.
   %
   % Example
   %
   %  Find recession events in one year of daily streamflow data:
   %
   %     [T, Q, R] = baseflow.loadExampleData();
   %     [t, q, r, Info] = baseflow.eventfinder(T(1:365), Q(1:365), R(1:365));
   %     fprintf('Found %d events\n', numel(Info.istart))
   %
   % See also getevents, eventpicker, eventplotter
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [t, q, r, opts] = parseinputs(t, q, r, mfilename, varargin{:});

   % MAIN CODE
   % Bound the rounding error of the flow values once for the whole
   % series. getevents smooths the whole series, so each segment carries
   % the error of the whole series (see Numerical zero in the help).
   [E1, qscale] = roundingbound(q, opts.qerror);

   [iS, iE] = nonnansegments(q, opts.nmin);

   [T, Q, R, Info] = arrayfun(@(s, e) ...
      eventsplitter(t(s:e), q(s:e), r(s:e), opts, E1, qscale), iS, iE, ...
      'Uniform', false);

   if isempty(T)
      [T, Q, R, Info] = setEventEmpty();
      return
   end

   % iS is the start of the entire flow segment, but the indices in Info are
   % relative to the event returned by eventsplitter. Add iS to these indices,
   fields = fieldnames(Info{1});
   for n = 1:numel(Info)
      for m = 1:numel(fields)
         Info{n}.(fields{m}) = Info{n}.(fields{m}) + iS(n) - 1;
      end
   end
   [T, Q, R] = deal(vertcat(T{:}), vertcat(Q{:}), vertcat(R{:}));
   Info = catstructfields(1, Info{:});
end

function [T, Q, R, Info] = eventsplitter(t, q, r, opts, E1, qscale)
   %eventsplitter Split detected recession events into segments for fitting.
   %
   % Syntax
   %
   %     [T,Q,R,Info] = eventsplitter(t,q,r,opts,E1,qscale)
   %
   % Description
   %
   %     Split recession events detected by eventfinder into individual segments
   %     ready to fit with baseflow.fitab or baseflow.fitevents. For example, if
   %     an event is interrupted by rainfall or if rainfall is detected from
   %     convex dq/dt, the event can be split into separate segments thought to
   %     represent uninterrupted baseflow. Follows recommendations in Dralle et
   %     al. 2017.
   %
   % Required inputs
   %
   %     t           time
   %     q           flow (m3/time)
   %     r           rain (mm/time)
   %     opts        structure containing the following fields:
   %     nmin        minimum event length
   %     fmax        maximum # of missing values gap-filled
   %     rmax        maximum run of sequential constant values
   %     rmin        minimum rainfall required to censor flow (mm/day?)
   %     rmconvex    remove convex derivatives
   %     rmnochange  remove consecutive constant derivates
   %     rmrain      remove rainfall
   %     E1          rounding bound of the flow values and one difference
   %     qscale      max(abs(q)) of the whole series (see roundingbound)
   %
   % See also getevents, eventfinder, eventpicker, eventplotter

   persistent inoctave
   if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
   end

   % This method fails when nmin is 0 or 1, because runlength counts each
   % nan as a run of length 1. See isminlength.

   % Get a 3-day smoothed timeseries to control false positive convexity
   if inoctave
      qS = nanmovmean(q,3);
   else
      qS = movmean(q, 3, 'omitnan');
   end

   % First and second differences of the discharge and the smoothed discharge
   dqdt = [0; diff(q)];
   dqdtS = [0; diff(qS)];
   d2qdt = [0; diff(dqdt)];
   d2qdtS = [0; diff(dqdtS)];

   % Numerical-zero thresholds, in the units of each difference. A first
   % difference has absolute weights that sum to 2, and a second
   % difference 4. The 3-day mean adds at most 3*u*qscale. Below these
   % amounts a slope or curvature is rounding, not signal.
   E1S = E1 + 3 * (eps/2) * qscale;
   tslope = 2 * E1;
   tcurve = 4 * E1;
   tcurveS = 4 * E1S;

   % Part 1: find data to be excluded (run the filters)

   % filters: positive dq/dt, peaks +1 day, convex +1 day, and minima -1 day
   % islocalmax and islocalmin are the private peakfinder wrappers, because
   % Octave has no islocalmax or islocalmin.
   % Each test uses its numerical-zero threshold. An extremum of q must
   % rise above its neighbours by more than a slope threshold, and an
   % extremum of dq/dt by more than a curvature threshold, because
   % neighbouring slopes differ by a curvature.
   ipos = find(dqdt > tslope); % increasing flow (positive dq/dt)
   imax = find(islocalmax(q, tslope)); % local maxima
   imin = find(islocalmin(q, tslope)); % local minima
   icon = find(islocalmax(dqdt, tcurve) & islocalmax(dqdtS, tcurveS)) ...
      + 1; % convex + 1 day

   % This also finds the transitions from convex up to concave up
   % icon = find( (islocalmax(dqdt) & islocalmax(dqdtS)) | ...
   %   (islocalmin(dqdt) & islocalmin(dqdtS)) ) + 1;  % convex + 1 day

   % Dralle: keep if dq/dt<0 AND d2q/dt2>0 (concave up) in BOTH the raw and
   % smoothed data, i.e. exclude if both raw AND smoothed data are convex
   icon2 = find(d2qdt <= tcurve & d2qdtS <= tcurveS) - 1;
   icon2 = icon2(icon2 > 0);

   % icon always occurs on peaks and one day prior, remove them from icon,
   % the peak will remain in imax, and one day prior in ipos
   icon = icon(~ismember((icon), imax));

   % if the first (last) point is a local max (min), add them here. The
   % endpoint step is a slope, so it must exceed the slope threshold.
   if q(1) - q(2) > tslope
      imax = [1; imax];
   end
   if q(end-1) - q(end) > tslope
      imin = [imin; length(q)];
   end

   % Part 2: exclude the data (apply the filters)
   ibad = [ipos; imax; imax+1; imin];

   % remove the convex points if requested
   if opts.rmconvex == true
      ibad = [ibad; icon];
      if opts.rmrain == false
         ibad = [ibad; icon2]; % substitute for lack of rain data
      end
   end

   % exclude days with rain > rmin and convex recession
   % also exclude 3 days before/after and combine with ibad
   if opts.rmrain == true
      irain = find(r > opts.rmin);
      irain = unique(irain + [-3 -2 -1 0 1 2 3]);
      irain = irain(ismember(irain, icon2));
      ibad  = [ibad; irain(:)];
   end

   % exclude sequences of two or more of (dq/dt = 0) (see setconstantnan)
   if opts.rmnochange == true
      % runlength counts runs of equal values, so a numerically zero
      % curvature becomes exactly 0 and a real one becomes nan.
      inoc = d2qdt;
      iszero = abs(inoc) <= tcurve;
      inoc(iszero) = 0;
      inoc(~iszero) = nan;
      inoc = find(isminlength(inoc, opts.rmax));
      ibad = [ibad; inoc];
   end

   % take the unique indices and exclude 0 and >numel(q)
   ibad = unique(ibad);
   ibad(ibad <= 0) = [];
   ibad(ibad > numel(q)) = [];

   % Part 3: extract each valid recession event
   tfc = true(size(q));          % initialize candidates true
   tfk = ones(size(q));          % initialize keeper run lengths
   tfc(ibad) = false;            % set unuseable values false
   tfk(ibad) = nan;              % set unuseable values nan

   % find events >= min length
   [tfk,is,ie] = isminlength(tfk, opts.nmin);
   eventlength = ie - is + 1; % event (run) lengths

   % Remove events shorter than nmin and concave increasing flows
   keep = eventlength >= opts.nmin;
   for n = 1:numel(is)
      % The trend tests take the rounding bound of the flow values.
      if islineconvex(q(is(n):ie(n)), E1) ...
         || islinepositive(q(is(n):ie(n)), E1)
         keep(n) = false;
      end
   end
   is = is(keep);
   ie = ie(keep);

   % pull out the events
   T = arrayfun(@(s, e) t(s:e), is, ie, 'Uniform', false);
   Q = arrayfun(@(s, e) q(s:e), is, ie, 'Uniform', false);
   R = arrayfun(@(s, e) r(s:e), is, ie, 'Uniform', false);

   % return events that passed the nmin filter
   Info.imaxima    = imax;
   Info.iminima    = imin;
   Info.iconvex    = icon;
   Info.icandidate = find(tfc);
   Info.ikeep      = find(tfk);
   Info.istart     = is;
   Info.istop      = ie;

   % debug plot:
   debug = false;
   if debug == true
      figure; plot(t, q); hold on; plot(t, qS, 'g'); datetick;
      scatter(t(ipos), q(ipos), 'filled')
      plot(t(imax), q(imax), 'x', 'MarkerSize', 20, 'Color', 'g')
      plot(t(imin), q(imin), 'x', 'MarkerSize', 20, 'Color', 'r')
      plot(t(icon), q(icon), 'o', 'MarkerSize', 20, 'Color', 'm')
      plot(t(icon2), q(icon2), '.', 'Color', 'k')
      plot(t(ibad), q(ibad), '.', 'Color', 'r')

      % highlight a particular event
      % scatter(t(is(n):ie(n)),q(is(n):ie(n)),'y','filled')

      % plot q vs -dqdt
      % figure; hold on;
      % for n = 1:numel(Q)
      %    loglog(Q{iplot},-derivative(Q{iplot}))
      %    title(num2str(n)); pause; clf
      % end
   end

end

%% ROUNDING BOUND
function [E1, qscale] = roundingbound(q, qerror)
   %ROUNDINGBOUND Bound the rounding error of the flow values.
   %
   %  [E1, qscale] = roundingbound(q, qerror) returns qscale = max(abs(q))
   %  over the finite values of q and E1 = qerror + 2*u*qscale, with
   %  u = eps/2. qerror bounds the rounding error of each value of q, and
   %  2*u*qscale covers the rounding of one difference. An empty qerror
   %  means one rounding per value, u*qscale. A series with no finite
   %  value gives E1 = 0.
   qscale = max(abs(q(isfinite(q))));
   if isempty(qscale)
      qscale = 0;
   end
   if isempty(qerror)
      qerror = (eps/2) * qscale;
   end
   E1 = qerror + 2 * (eps/2) * qscale;
end

%% INPUT PARSER
function [t, q, r, opts] = parseinputs(t, q, r, funcname, varargin)

   % Take the option defaults from setopts so that getevents, wrapevents,
   % and eventfinder use the same values.
   persistent parser
   if isempty(parser)
      defaults = baseflow.setopts('getevents');
      parser = inputParser;
      addRequired(parser, 't',                  @isdatelike);
      addRequired(parser, 'q',                  @isdoublevector);
      addRequired(parser, 'r',                  @isnumeric);
      addParameter(parser,'nmin',       defaults.nmin,       @isnumericscalar);
      addParameter(parser,'fmax',       defaults.fmax,       @isnumericscalar);
      addParameter(parser,'rmax',       defaults.rmax,       @isnumericscalar);
      addParameter(parser,'rmin',       defaults.rmin,       @isnumericscalar);
      addParameter(parser,'rmconvex',   defaults.rmconvex,   @islogicalscalar);
      addParameter(parser,'rmnochange', defaults.rmnochange, @islogicalscalar);
      addParameter(parser,'rmrain',     defaults.rmrain,     @islogicalscalar);
      % The rounding bound of q is a property of the data, not a setopts
      % policy, so its default is empty: one rounding per value.
      addParameter(parser,'qerror',     [],                  @isqerror);
   end
   parser.FunctionName = funcname;
   parse(parser,t,q,r,varargin{:});
   
   % Return the options structure
   opts = parser.Results;

   % Convert datetime to double if datetime was passed in
   t = todatenum(t);
   validateattributes(t, {'double'}, {'size', size(q)}, funcname, 't', 1)
   validateattributes(opts.nmin, {'double'}, {'>', 2}, funcname, 'nmin')
   validateattributes(opts.rmax, {'double'}, {'>', 1}, funcname, 'rmax')

   % Allow empty r i.e. input syntax eventfinder(t,q,[],...)
   if isempty(r)
      r = zeros(size(t));
   end

   % Convert to columns, in case this is not called from baseflow.getevents
   [t, q, r] = deal(t(:), q(:), r(:));
end

function tf = isqerror(x)
   %ISQERROR True for an empty value or a nonnegative finite scalar.
   tf = isempty(x) || (isnumeric(x) && isscalar(x) && isfinite(x) && x >= 0);
end
