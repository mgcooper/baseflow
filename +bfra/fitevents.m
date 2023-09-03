function [Fits,Results] = fitevents(Events,varargin)
   %FITEVENTS wrapper around getdqdt and fitdqdt functions to fit all events
   %
   % Syntax
   %
   %     [Fits,Results] = fitevents(Events,varargin)
   %
   % Description
   %
   %     [Fits,Results] = fitevents(Events) fits all recession events in Events
   %     (output of bfra.getevents) using default algorithm options.
   %
   %     [Fits,Results] = fitevents(Events,opts) uses user-supplied
   %     algorithm options in struct opts. See bfra.setopts to set options.
   %
   % Required inputs
   %
   %     Events: output of bfra.getevents (flow comes in as m3 d-1 posted daily)
   %
   % Outputs
   %
   %     Fits: structure containing the fitted q/dqdt data
   %     Results: table of fitted values e.g., a, b, tau, for each event
   %
   % See also getevents, getdqdt, fitdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
   %
   % TODO: move subfunctions to private/ to manage warnings, input parsing, and
   % special-case fitting routines including octave compatibility once, here.
   % This will be most problematic for fitab, because it is useful as a
   % standalone function for fitting a single event.

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   %#ok<*ASGLU>
   [derivmethod, fitmethod, fitorder, pickfits, pickmethod, plotfits, ...
      saveplots, etsparam, vtsparam, fitopts] = parseinputs( ...
      Events, mfilename, varargin{:});

   % MAIN FUNCTION

   eventTime = Events.eventTime;               % time [days]
   eventFlow = Events.eventFlow;               % daily discharge [m3 d-1]
   eventRain = Events.eventRain;               % daily rainfall [mm d-1]
   eventTags = Events.eventTags;
   numEvents = max(eventTags);

   % try
   %    T = datetime(T,'ConvertFrom','datenum');
   % catch
   % end

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
   if isoctave
      %warning('off','Octave:invalid-fun-call');
      warning('off','Octave:nearly-singular-matrix');
   else
      warning('off','MATLAB:rankDeficientMatrix');
      warning('off','stats:nlinfit:IterationLimitExceeded');
      warning('off','stats:nlinfit:ModelConstantWRTParam');
      warning('off','stats:nlinfit:IllConditionedJacobian');
      warning('off','bfra:deps:rsquare:NegativeRsquared');
   end

   debugflag = false;

   % compute the recession constants
   for thisEvent = 1:numEvents

      eventI = eventTags == thisEvent;
      eventT = eventTime(eventI);
      eventQ = eventFlow(eventI);
      eventR = eventRain(eventI);
      eventDate = mean(eventT); % keep track of the event date

      % if this is activated, need method to plot in getdqdt
      % if thisEvent == 1 && plotfits == true
      %    figure('Position',[1 1 658  576]); ax = gca;
      % end

      % get the q, dq/dt estimates (H = Hat)

      [qH,dH,dtH,tH] = bfra.getdqdt(eventT, eventQ, eventR, derivmethod,   ...
         'pickmethod', pickmethod, 'fitmethod', fitmethod, 'etsparam', ...
         etsparam, 'vtsparam', vtsparam);

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
            [iFit, ok] = bfra.fitab(q, dqdt, fitmethod, 'fitopts', fitopts);
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


   % TURN WARNINGS BACK ON
   if isoctave
      warning('on','Octave:nearly-singular-matrix');
   else
      warning('on','MATLAB:rankDeficientMatrix');
      warning('on','stats:nlinfit:IterationLimitExceeded');
      warning('on','stats:nlinfit:ModelConstantWRTParam');
      warning('on','stats:nlinfit:IllConditionedJacobian');
      warning('on','bfra:deps:rsquare:NegativeRsquared');
   end
end

% PREP FITS
function [q, dqdt, dt, tq, ok] = preparefit(q, dqdt, dt, tq, thisfit)

   % if there are multiple fits for an event, qHat, dHat, etc. will be cell
   % arrays. this pulls out the selected values to fit.

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
      Fits, iFit, savevars, ok)

   % if fitting failed, set this event nan, otherwise save the fit
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
      fitIdx = ismember(T,tq);
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

   else

      % this shouldn't be necessary since they're initialized to nan

      %    K.a(fitcount) = nan;
      %    K.b(fitcount) = nan;
      %    K.aL(fitcount) = nan;
      %    K.bL(fitcount) = nan;
      %    K.aH(fitcount) = nan;
      %    K.bH(fitcount) = nan;
      %    K.rsq(fitcount) = nan;
      %    K.pvalue(fitcount) = nan;
      %    K.N(fitcount) = nan;
      %    K.eventTag(fitcount) = eventtag;
      %    K.fitTag(fitcount) = fittag;

      % K(idx).method = method;
      % K(idx).order = order;
      % K(idx).deriv = deriv;
      % K(idx).station = station;
      % K(idx).date = date;

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
      plotfits, saveplots, etsparam, vtsparam, fitopts] = parseinputs( ...
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
   end
   parser.FunctionName = funcname;
   parser.parse(Events,varargin{:});

   fitopts = struct();
   fitorder = parser.Results.fitorder;
   pickfits = parser.Results.pickfits;
   plotfits = parser.Results.plotfits;
   etsparam = parser.Results.etsparam;
   vtsparam = parser.Results.vtsparam;
   saveplots = parser.Results.saveplots;
   fitmethod = parser.Results.fitmethod;
   pickmethod = parser.Results.pickmethod;
   derivmethod = parser.Results.derivmethod;
end