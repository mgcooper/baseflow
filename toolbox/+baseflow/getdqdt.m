function [q,dqdt,dt,tq,rq,varargout] = getdqdt(T,Q,R,derivmethod,varargin)
   %GETDQDT Numerical estimation of the time derivative of discharge dQ/dt.
   %
   % Syntax
   %
   %     [q,dqdt,dt,tq,rq] = baseflow.getdqdt(T,Q,R,derivmethod)
   %     [q,dqdt,dt,tq,rq] = baseflow.getdqdt(_,'ctsmethod',ctsmethod)
   %     [q,dqdt,dt,tq,rq] = baseflow.getdqdt(_,'fitmethod',fitmethod)
   %     [q,dqdt,dt,tq,rq] = baseflow.getdqdt(_,'pickmethod',pickmethod)
   %     [q,dqdt,dt,tq,rq,Info,hFits] = baseflow.getdqdt(_)
   %
   % Description
   %
   %     [q,dqdt,dt,tq,rq] = baseflow.getdqdt(T,Q,R,derivmethod) computes dQ/dt
   %     using variable time stepping (VTS), exponential time stepping (ETS),
   %     or a constant time step (CTS) with one of six standard numerical
   %     derivatives given in Thomas et al. 2015, Table 2.
   %     The method is passed in as the argument derivmethod with type char.
   %
   %     [q,dqdt,dt,tq,rq,Info,hFits] = baseflow.getdqdt(_) also returns the
   %     pick information and the fit handles from plotdqdt. getdqdt calls
   %     plotdqdt only when neither fitmethod nor pickmethod is 'none'. In
   %     that case, q, dqdt, dt, and tq are cell arrays with one cell per
   %     pick. Otherwise, Info and hFits are nan.
   %
   % Required inputs
   %
   %     T: time (days)
   %     Q: discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
   %     R: rainfall (L T^-1, assumed to be mm d-1)
   %     derivmethod: method to compute numerical derivative dQ/dt. Options
   %     are: 'VTS', 'ETS', 'CTS'. fitevents and setopts use 'ETS' by
   %     default.
   %
   % Optional name-value inputs
   %
   %     ctsmethod: char, finite-difference stencil for the CTS method:
   %        'B1' (backward, first order), 'B2' (backward, second order),
   %        'F1' (forward, first order), 'F2' (forward, second order),
   %        'C2' (centered, second order), or 'C4' (centered, fourth
   %        order). Default: 'B1'.
   %     etsparam: scalar double, parameter that controls window size in ETS
   %        method. Default: 0.2.
   %     vtsparam: scalar double, parameter that controls window size in VTS
   %        method. Default: 1.
   %     fitmethod: char, fitab method that plotdqdt uses to fit
   %        -dQ/dt = aQ^b, for example 'nls', 'ols', or 'qtl'. 'none'
   %        skips the fit. Note: fitab does not support 'mle'. Default:
   %        'nls'.
   %     pickmethod: char, method that plotdqdt uses to pick the fit
   %        segments: 'none', 'auto', or 'manual'. 'none' skips the fit.
   %        Default: 'none'.
   %     plotfits: logical, scalar, indicates whether plotdqdt plots the
   %        fits. Default: false.
   %     eventID: char, event label that getdqdt passes to plotdqdt.
   %        Default: 'none'.
   %
   % Example
   %
   %  Compute dQ/dt for the longest detected recession event with the
   %  exponential time stepping (ETS) method:
   %
   %     [T, Q, R] = baseflow.loadExampleData();
   %     Events = baseflow.getevents(T, Q, R);
   %     i = Events.eventTags == mode(Events.eventTags);
   %     [q, dqdt] = baseflow.getdqdt(Events.eventTime(i), ...
   %        Events.eventFlow(i), Events.eventRain(i), 'ETS');
   %     fprintf('%d fitted values\n', sum(~isnan(dqdt)))
   %
   % See also: fitdqdt
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % Tip: this accepts pre-selected events, not raw timeseries. Use
   % baseflow.findevents to pick Events, then baseflow.getdqdt to fit the
   % events. This is a wrapper for multi-year, final analysis.

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [T, vtsparam, etsparam, ctsmethod, pickmethod, fitmethod, plotfits, eventID] = ...
      parseinputs(T,Q,R,derivmethod,mfilename,varargin{:});

   % MAIN FUNCTION
   switch derivmethod

      case 'VTS'  % variable time step

         [q,dqdt,dt,tq,rq] = fitvts(T,Q,R,'vtsparam',vtsparam);

      case 'ETS'  % exponential timestep

         [q,dqdt,dt,tq,rq] = fitets(T,Q,R,'etsparam',etsparam);

      case 'CTS'  % constant time step

         [q,dqdt,dt,tq,rq] = fitcts(T,Q,R,ctsmethod);
   end

   % this is where islineconvex and/or islinepositive to q and/or dqdt would be
   % to catch all cases regardless of fit method, but if the fitxxx functions
   % are called outside of this function, those cases wouldn't be caught, so
   % either move those functions to private/ or add checks to them.

   % this is the case where dQ/dt and q are returned without fitting a/b
   if strcmp(fitmethod,'none') || strcmp(pickmethod,'none')
      varargout{1} = nan;
      varargout{2} = nan;
      return
   else
      % if pickmethod = "none", we don't need anything else so we could stop
      % here, but fitSelector will repackage the event as a cell array which is
      % consistent with the case where pickmethod ~= "none" which are the
      % options to subdivide events into segments, for example early-time and
      % late-time. It also returns Info which is needed to parse sub-event
      % picks.

      [hFits,Picks] = baseflow.plotdqdt(q,dqdt,'fitmethod',fitmethod,'pickmethod',...
         pickmethod,'plotfits',plotfits,'eventID',eventID,'rain',rq);

      [q,dqdt,dt,tq,rq,Info] = packagefits(Picks,q,dqdt,dt,tq,R);

      varargout{1} = Info;
      varargout{2} = hFits;
   end
end

% PACKAGEFITS
function [Q,dQdT,dT,T,R,Info] = packagefits(Picks,q,dqdt,dt,tq,rq)

   % this unpacks the Picks structure and repackages the T,Q,dQdt for each
   % picked fit as individual cell arrays. I am not sure why I don't just do:
   % Q = Picks.Q;
   % dQdt = Picks.dQdt;
   % and so on. But, Picks does not include T, and maybe I wanted to distinguish
   % the og T,Q from the ets/vts fit t,q.
   % EITHER WAY, after moving fitdqdt calls to fitets/fitvts into this function
   % abve, I confirmed that things work up to this point meaning I can still
   % select events in plotdqdt and they get sent here, but I think the way i
   % deal wtih retiming in ETS now throws off the istart/stop, so will need to
   % figure out if it's being done correctly if I use manual or auto picking.


   % if no events are found, return nan
   if ~iscell(Picks.Q) && isnan(Picks.Q)
      T=nan;Q=nan;R=nan;dT=nan;dQdT=nan;Info=nan; return
   end

   numPicks = numel(Picks.Q);
   T = cell(numPicks,1);
   Q = cell(numPicks,1);
   R = cell(numPicks,1);
   dT = cell(numPicks,1);
   dQdT = cell(numPicks,1);

   for m = 1:numPicks

      istart = Picks.istart(m);
      istop = Picks.istop(m);

      % previously these were put into Fits structure but I
      Q{m} = q(istart:istop);
      dQdT{m} = dqdt(istart:istop);
      dT{m} = dt(istart:istop);
      T{m} = tq(istart:istop);
      R = rq(istart:istop);

      Info.istart(m) = istart;
      Info.istop(m) = istop;
      Info.runlengths(m) = Picks.runlengths(m);
   end
end

%% INPUT PARSER
function [T,vtsparam,etsparam,ctsmethod,pickmethod,fitmethod,plotfits,eventID] = ...
      parseinputs(T,Q,R,derivmethod,funcname,varargin)

   persistent parser
   if isempty(parser)
      parser = inputParser;
      parser.CaseSensitive = true;
      parser.addRequired('T', @isdatelike);
      parser.addRequired('Q', @isnumericvector);
      parser.addRequired('R', @isnumeric);
      parser.addRequired('derivmethod', @ischar);
      parser.addParameter('pickmethod', 'none', @ischar);
      parser.addParameter('fitmethod', 'nls', @ischar);
      parser.addParameter('ctsmethod', 'B1', @ischar);
      parser.addParameter('vtsparam', 1, @isnumericscalar);
      parser.addParameter('etsparam', 0.2, @isnumericscalar);
      parser.addParameter('plotfits', false, @islogicalscalar);
      parser.addParameter('eventID', 'none', @ischar);
   end
   parser.FunctionName = funcname;
   parser.parse(T,Q,R,derivmethod,varargin{:});

   vtsparam    = parser.Results.vtsparam;
   etsparam    = parser.Results.etsparam;
   ctsmethod   = parser.Results.ctsmethod;
   pickmethod  = parser.Results.pickmethod;
   fitmethod   = parser.Results.fitmethod;
   plotfits    = parser.Results.plotfits;
   eventID     = parser.Results.eventID;

   % Convert datetime to double if datetime was passed in
   T = todatenum(T);
end
