function [Fits,Results] = fitevents(Events,varargin)
   %FITEVENTS Wrapper around getdqdt and fitdqdt functions to fit all events.
   %
   % Syntax
   %
   %     [Fits,Results] = fitevents(Events,varargin)
   %
   % Description
   %
   %     [Fits,Results] = fitevents(Events) fits all recession events in Events
   %     (output of baseflow.getevents) using default algorithm options.
   %
   %     [Fits,Results] = fitevents(Events,opts) uses user-supplied
   %     algorithm options in struct opts. See baseflow.setopts to set options.
   %
   %     Note: this function fits all events individually. To fit all events
   %     simultaneously (using the point cloud), use baseflow.fitab.
   %
   % Required inputs
   %
   %     Events: output of baseflow.getevents (flow in m3 d-1 posted daily)
   %
   % Optional inputs
   %
   %     See baseflow.setopts for the name-value options and their defaults.
   %
   %     fitopts: struct of baseflow.fitab options passed to every event fit
   %     (default: struct()). Allowed fields are weights, order, quantile,
   %     refqtls, Nboot, and alpha (numeric), and mask and plotfit
   %     (logical). A fitopts field overrides the same-named fitab option,
   %     so fitopts.order overrides fitorder. weights and mask must be
   %     scalars, because each event fit has its own points; any other size
   %     raises baseflow:fitevents:nonscalarFitopt. An unknown field raises
   %     baseflow:fitab:unknownFitopt. A field of the wrong type raises
   %     baseflow:fitab:invalidFitopt.
   %
   % Outputs
   %
   %     Fits: structure containing the fitted q/dqdt data
   %     Results: table of fitted values e.g., a, b, tau, for each event
   %
   % Examples
   %
   %  Detect events, then fit each event with a linear reservoir model:
   %
   %     [T, Q, R] = baseflow.loadExampleData();
   %     opts = baseflow.setopts('getevents');
   %     Events = baseflow.getevents(T, Q, R, opts);
   %     opts = baseflow.setopts('fitevents', 'fitorder', 1);
   %     [EventFits, Results] = baseflow.fitevents(Events, opts);
   %
   %  Note: to fit all events simultaneously, use baseflow.fitab on the
   %  point cloud. To fit the point cloud with a linear reservoir model:
   %
   %     abFit = baseflow.fitab(EventFits.q, EventFits.dqdt, 'nls', ...
   %        'order', 1, 'plotfit', true);
   %     fprintf('a = %.4f, b = %.2f\n', abFit.a, abFit.b)
   %
   %
   % See also getevents, getdqdt, fitdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
   %
   % TODO: move subfunctions to private/ to manage warnings, input parsing, and
   % special-case fitting routines including octave compatibility once, here.
   % This will be most problematic for fitab, because it is useful as a
   % standalone function for fitting a single event.
   %
   % Note: getdqdt and fitab share 'fitmethod' (nls, ols, mle, none, qtl).
   % The fitab-only methods 'envelope', 'mean', and 'median' cannot be
   % selected here. To fit events with a linear reservoir model, set
   % 'fitorder' to 1. With fitmethod 'nls' or 'ols', fitab then forces a
   % line of slope 1.


   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   %#ok<*ASGLU>
   [derivmethod, fitmethod, fitorder, pickfits, pickmethod, plotfits, ...
      saveplots, etsparam, vtsparam, ctsmethod, fitopts] = parseinputs( ...
      Events, mfilename, varargin{:});

   % MAIN FUNCTION

   eventTime = Events.eventTime;               % time [days]
   eventFlow = Events.eventFlow;               % daily discharge [m3 d-1]
   eventRain = Events.eventRain;               % daily rainfall [mm d-1]
   eventTags = Events.eventTags;
   numEvents = max(eventTags);

   % initialize output structure and output arrays
   Fits.eventTime = Events.eventTime;            % event-times
   Fits.eventFlow = Events.eventFlow;            % detected event-Q
   Fits.eventTags = nan(size(eventFlow));        % 1:numEvents
   Fits.t         = nan(size(eventFlow));        % fitted t  % NaT(size(Q));
   Fits.q         = nan(size(eventFlow));        % fitted Q
   Fits.r         = nan(size(eventFlow));        % rain
   Fits.dt        = nan(size(eventFlow));        % fitted dt
   Fits.dqdt      = nan(size(eventFlow));        % fitted dQdt
   Fits.fitTags   = nan(size(eventFlow));        % 1:numFits
   nFits          =  0;

   if pickmethod == "none"
      Results = initFitTable(numEvents);
   else
      Results = initFitTable(numEvents*4); % allocate up to 4 picks/event
   end
   savevars = {'a','b','aL','aH','bL','bH','rsq','pvalue','N'};

   % manage warnings
   % Nonlinear fits to recession events raise these expected warnings. If
   % dQ/dt increases as Q decreases, nlinfit raises rankDeficientMatrix or
   % ModelConstantWRTParam. A convex Q vs -dQ/dt relation does not fit the
   % model form, so nlinfit raises IllConditionedJacobian. Both cases can
   % also raise IterationLimitExceeded.
   if isoctave
      %warning('off','Octave:invalid-fun-call');
      withwarnoff({ ...
         'Octave:nearly-singular-matrix'} ...
         );
   else
      withwarnoff({ ...
         'MATLAB:rankDeficientMatrix', ...
         'stats:nlinfit:IterationLimitExceeded', ...
         'stats:nlinfit:ModelConstantWRTParam', ...
         'stats:nlinfit:IllConditionedJacobian', ...
         'baseflow:deps:rsquare:NegativeRsquared'} ...
         );
   end

   % compute the recession constants
   for thisEvent = 1:numEvents

      eventI = eventTags == thisEvent;
      eventT = eventTime(eventI);
      eventQ = eventFlow(eventI);
      eventR = eventRain(eventI);
      eventDate = mean(eventT); % keep track of the event date

      % get the q, dq/dt estimates (H = Hat). getdqdt passes plotfits to
      % plotdqdt, which draws one figure per event. plotdqdt fits the
      % point cloud with its own defaults to draw the line, so the drawn
      % line uses fitmethod alone, not fitorder or fitopts.

      [qH,dH,dtH,tH] = baseflow.getdqdt(eventT, eventQ, eventR, derivmethod,   ...
         'pickmethod', pickmethod, 'fitmethod', fitmethod, 'etsparam', ...
         etsparam, 'vtsparam', vtsparam, 'ctsmethod', ctsmethod, ...
         'plotfits', plotfits, 'eventID', sprintf('%d', thisEvent));

      % undocumented feature
      if saveplots == true
         % yyyyMMMdd = sprintf('%d_%d_%d',year(eventT),month(eventT),day(eventT));
         % fname = ['dqdt_' yyyyMMMdd '.png'];
         % pauseSaveFig('s',fname);
      end

      % if pickFits is true, then qHat, dHat, and tHat will be cell arrays
      numFits = 1;
      if iscell(qH)
         numFits = numel(qH);
      end

      for thisFit = 1:numFits

         [q, dqdt, dt, tq, ok] = preparefit(qH, dH, dtH, tH, thisFit);

         % if no flow was returned, continue, otherwise fit a/b
         if ok == false
            continue
         else
            % fitopts fields override fitab's same-named options; fitab
            % validates them and errors on an unknown field.
            [iFit, ok] = baseflow.fitab(q, dqdt, fitmethod, ...
               'order', fitorder, 'fitopts', fitopts);
         end

         [Fits, Results, nFits] = saveFit(eventTime, q, dqdt, dt, tq, ...
            derivmethod, fitmethod, fitorder, eventDate, thisEvent, ...
            thisFit, nFits, Results, Fits, iFit, savevars, ok);
      end
   end

   % remove fits that weren't kept
   ikeep = ~isnan(Results.a);
   vars = fieldnames(Results);
   for n = 1:numel(vars)
      Results.(vars{n}) = Results.(vars{n})(ikeep);
   end
end

% PREP FITS
function [q, dqdt, dt, tq, ok] = preparefit(q, dqdt, dt, tq, thisfit)

   % if there are multiple fits for an event, qHat, dHat, etc. will be cell
   % arrays. this pulls out the selected values to fit. Otherwise, it simply
   % returns the inputs as outputs.

   if iscell(q)
      q = q{thisfit};
      dqdt = dqdt{thisfit};
      dt = dt{thisfit};
      tq = tq{thisfit};
   end

   % if no flow was returned, continue
   if all(isnan(q))
      ok = false;
   else
      ok = true;
   end
end


% GET FITS
function [Fits, K, fitcount] = saveFit(T, q, dqdt, dt, tq, derivmethod, ...
      fitmethod, fitorder, eventdate, eventtag, fittag, fitcount, K, ...
      Fits, iFit, savevars, ok) %#ok<INUSD>

   % Save the fit only if fitting succeeded. initFitTable fills K with nan,
   % and fitevents removes the unused nan rows after the event loop.
   if ok == true

      fitcount = fitcount+1;

      for n = 1:numel(savevars)
         K.(savevars{n})(fitcount) = iFit.(savevars{n});
      end

      K.eventTag(fitcount) = eventtag;
      K.fitTag(fitcount) = fittag;

      %    K.method(fitcount) = fitmethod;
      %    K.order(fitcount) = fitorder;
      %    K.deriv(fitcount) = derivmethod;
      %    K.station(fitcount) = station;
      %    K.date(fitcount) = eventdate;


      % collect all data for the point-cloud
      fitIdx = ismember(T, tq);
      %fitIdx = ismember(T,datenum(tq)); % TEST
      Fits.q(        fitIdx) = q;
      Fits.dqdt(     fitIdx) = dqdt;
      Fits.dt(       fitIdx) = dt;
      Fits.t(        fitIdx) = tq;
      Fits.eventTags(fitIdx) = eventtag;
      Fits.fitTags(  fitIdx) = fittag;

      % at this point, with new ets retiming, we need to remove nan to have
      % eventTag and fitTag only span the rows with valid data, but as-is, we
      % should have eventTag equal to the raw data, and since the fitted data is
      % nan elsewhere, this might be better
   end
end

function K = initFitTable(N)
   K.a = nan(N,1);
   K.b = nan(N,1);
   K.aL = nan(N,1);
   K.bL = nan(N,1);
   K.aH = nan(N,1);
   K.bH = nan(N,1);
   K.rsq = nan(N,1);
   K.pvalue = nan(N,1);
   K.N = nan(N,1);
   K.eventTag = nan(N,1);
   K.fitTag = nan(N,1);

   % these need to be redefined as strings or chars or soemthing other than nan
   % K.method = nan(N,1);
   % K.order = nan(N,1);
   % K.deriv = nan(N,1);
   % K.station = nan(N,1);
   % K.date = nan(N,1);
end

%% INPUT PARSER
function [derivmethod, fitmethod, fitorder, pickfits, pickmethod, ...
      plotfits, saveplots, etsparam, vtsparam, ctsmethod, fitopts] = ...
      parseinputs( ...
      Events, funcname, varargin)

   persistent parser
   if isempty(parser)
      parser = inputParser;
      parser.StructExpand = true;
      parser.addRequired( 'Events',               @isstruct         );
      parser.addParameter('derivmethod', 'ETS',   @ischar           );
      parser.addParameter('fitmethod',   'nls',   @ischar           );
      parser.addParameter('fitorder',    nan,     @isnumericscalar  );
      parser.addParameter('pickfits',    false,   @islogicalscalar  );
      parser.addParameter('pickmethod',  'none',  @ischar           );
      parser.addParameter('plotfits',    false,   @islogicalscalar  );
      parser.addParameter('saveplots',   false,   @islogicalscalar  );
      parser.addParameter('etsparam',    0.2,     @isnumericscalar  );
      parser.addParameter('vtsparam',    1.0,     @isnumericscalar  );
      parser.addParameter('ctsmethod',   'B1',    @ischar           );
      parser.addParameter('fitopts',     struct(), @isstruct        );
   end
   parser.FunctionName = funcname;
   parser.parse(Events,varargin{:});

   % fitab validates the fitopts fields and errors on an unknown one.
   fitopts = parser.Results.fitopts;

   % fitab applies weights and mask point by point. Each event has its own
   % q and dqdt, so one vector cannot match the points of every event fit.
   % Only a scalar weights or mask value applies to all of the fits.
   if any(cellfun(@(f) isfield(fitopts, f) && ~isscalar(fitopts.(f)), ...
         {'weights', 'mask'}))
      error('baseflow:fitevents:nonscalarFitopt', ...
         ['fitopts.weights and fitopts.mask must be scalars in fitevents. ' ...
         'Use baseflow.fitab to weight or mask the points of one fit.'])
   end
   fitorder = parser.Results.fitorder;
   pickfits = parser.Results.pickfits;
   plotfits = parser.Results.plotfits;
   etsparam = parser.Results.etsparam;
   vtsparam = parser.Results.vtsparam;
   ctsmethod = parser.Results.ctsmethod;
   saveplots = parser.Results.saveplots;
   fitmethod = parser.Results.fitmethod;
   pickmethod = parser.Results.pickmethod;
   derivmethod = parser.Results.derivmethod;
end
