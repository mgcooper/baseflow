function [T, Q, R, Info] = eventfinder(t, q, r, varargin)
   %EVENTFINDER find recession events using hydrograph and rainfall timeseries.
   %
   % Syntax
   %
   %     [T,Q,R,Info] = eventfinder(t,q,r)
   %     [T,Q,R,Info] = eventfinder(t,q,r,opts)
   %     [T,Q,R,Info] = eventfinder(_, 'qmin', qmin)
   %     [T,Q,R,Info] = eventfinder(_, 'nmin', nmin)
   %     [T,Q,R,Info] = eventfinder(_, 'fmax', fmax)
   %     [T,Q,R,Info] = eventfinder(_, 'rmax', rmax)
   %     [T,Q,R,Info] = eventfinder(_, 'rmin', rmin)
   %     [T,Q,R,Info] = eventfinder(_, 'rmrain', true)
   %     [T,Q,R,Info] = eventfinder(_, 'rmconvex', true)
   %     [T,Q,R,Info] = eventfinder(_, 'rmnochange', false)
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
   %     opts        (optional) structure containing the following fields:
   %     qmin        minimum flow magnitude
   %     nmin        minimum event length
   %     fmax        maximum # of missing values gap-filled
   %     rmax        maximum run of sequential constant values
   %     rmin        minimum rainfall required to censor flow (mm/day?)
   %     cmax        maximum run of sequential constant values
   %     rmconvex    remove convex derivatives
   %     rmnochange  remove consecutive constant derivates
   %     rmrain      remove rainfall
   %
   % See also getevents, eventsplitter, eventpicker, eventplotter
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [t, q, r, opts] = parseinputs(t, q, r, mfilename, varargin{:});

   % MAIN CODE
   [iS, iE] = nonnansegments(q, opts.nmin);

   [T, Q, R, Info] = arrayfun(@(s, e) ...
      eventsplitter(t(s:e), q(s:e), r(s:e), opts), iS, iE, 'Uniform', false);

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

function [T, Q, R, Info] = eventsplitter(t, q, r, opts)
   %eventsplitter Split detected recession events into segments for fitting.
   %
   % Syntax
   %
   %     [T,Q,R,Info] = eventsplitter(t,q,r,opts)
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
   %
   % See also getevents, eventfinder, eventpicker, eventplotter

   persistent inoctave
   if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
   end

   % if nmin is set to 0 (and maybe if it is set to 1) this method will fail
   % because runlength returns 1 for consecutive nan values, see isminlength.

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

   % Part 1: find data to be excluded (run the filters)

   % filters: positive dq/dt, peaks +1 day, convex +1 day, and minima -1 day
   ipos = find(dqdt > 0); % increasing flow (positive dq/dt)
   imax = find(islocalmax(q)); % local maxima
   imin = find(islocalmin(q)); % local minima
   icon = find(islocalmax(dqdt) & islocalmax(dqdtS)) + 1;  % convex + 1 day

   % This also finds the transitions from convex up to concave up
   % icon = find( (islocalmax(dqdt) & islocalmax(dqdtS)) | ...
   %   (islocalmin(dqdt) & islocalmin(dqdtS)) ) + 1;  % convex + 1 day

   % Dralle: keep if dq/dt<0 AND d2q/dt2>0 (concave up) in BOTH the raw and
   % smoothed data, i.e. exclude if both raw AND smoothed data are convex
   icon2 = find(d2qdt <= 0 & d2qdtS <= 0) - 1;
   icon2 = icon2(icon2 > 0);

   % icon always occurs on peaks and one day prior, remove them from icon,
   % the peak will remain in imax, and one day prior in ipos
   icon = icon(~ismember((icon), imax));

   % if the first (last) point is a local max (min), add them here
   if q(2) < q(1)
      imax = [1; imax];
   end
   if q(end) < q(end-1)
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
      inoc = d2qdt; inoc(inoc ~= 0) = nan;
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
      if islineconvex(q(is(n):ie(n))) || islinepositive(q(is(n):ie(n)))
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

function tf = islocalmax(X)
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,0,1,false)) = true;
end

function tf = islocalmin(X)
   tf = false(size(X));
   tf(baseflow.deps.peakfinder(X,0,0,-1,false)) = true;
end

%% INPUT PARSER
function [t, q, r, opts] = parseinputs(t, q, r, funcname, varargin)

   persistent parser
   if isempty(parser)
      parser = inputParser;
      addRequired(parser, 't',                  @isdatelike);
      addRequired(parser, 'q',                  @isdoublevector);
      addRequired(parser, 'r',                  @isnumeric);
      addParameter(parser,'nmin',        4,     @isnumericscalar);
      addParameter(parser,'fmax',        2,     @isnumericscalar);
      addParameter(parser,'rmax',        2,     @isnumericscalar);
      addParameter(parser,'rmin',        0,     @isnumericscalar);
      addParameter(parser,'rmconvex',    false, @islogicalscalar);
      addParameter(parser,'rmnochange',  false, @islogicalscalar);
      addParameter(parser,'rmrain',      false, @islogicalscalar);
   end
   parser.FunctionName = funcname;
   parse(parser,t,q,r,varargin{:});
   
   % Return the options structure
   opts = parser.Results;

   % Convert datetime to double if datetime was passed in
   t = todatenum(t);
   validateattributes(t, {'double'}, {'size', size(q)}, funcname, 't', 1)
   validateattributes(opts.nmin, {'double'}, {'>', 2}, funcname, 'nmin')

   % Allow empty r i.e. input syntax eventfinder(t,q,[],...)
   if isempty(r)
      r = zeros(size(t));
   end

   % Convert to columns, in case this is not called from baseflow.getevents
   [t, q, r] = deal(t(:), q(:), r(:));
end