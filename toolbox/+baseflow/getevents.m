function [Events,Info] = getevents(T,Q,R,varargin)
   %GETEVENTS Get recession events from daily hydrograph timeseries T, Q, and R.
   %
   %% Syntax
   %
   %     Events = getevents(T,Q,R)
   %     [Events, Info] = getevents(T,Q,R,opts)
   %     [Events, Info] = getevents(_, 'qmin', qmin)
   %     [Events, Info] = getevents(_, 'nmin', nmin)
   %     [Events, Info] = getevents(_, 'fmax', fmax)
   %     [Events, Info] = getevents(_, 'rmax', rmax)
   %     [Events, Info] = getevents(_, 'rmin', rmin)
   %     [Events, Info] = getevents(_, 'cmax', cmax)
   %     [Events, Info] = getevents(_, 'rmrain', true)
   %     [Events, Info] = getevents(_, 'rmconvex', true)
   %     [Events, Info] = getevents(_, 'rmnochange', false)
   %     [Events, Info] = getevents(_, 'pickevents', true)
   %     [Events, Info] = getevents(_, 'plotevents', true)
   %     [Events, Info] = getevents(_, 'asannual', true)
   %
   %% Description
   %
   %     EVENTS = GETEVENTS(T, Q, R) Detects, processes, and organizes
   %     individual recession events from daily hydrograph timeseries T, Q, and
   %     rainfall R using default algorithm options. Event discharge,
   %     timestamps, and diagnostic info about the events are returned in output
   %     structure Events. Note: this function is a wrapper around eventfinder
   %     to perform pre- and post-processing and organize all recession events
   %     into the Events structure.
   %
   %     EVENTS = GETEVENTS(_, OPTS) Uses user-defined options in struct OPTS.
   %     Use baseflow.setopts to set default OPTS struct and custom optional values.
   %
   %     [EVENTS, INFO] = GETEVENTS(_) Also returns struct INFO which contains
   %     the indices of the identified local maxima, minima, convex points,
   %     candidate recession values, kept recession values, and the start and
   %     stop index of each kept event. Use this information with EVENTPLOTTER.
   %
   %     Tip: events are identified by their indices on the t,q,r arrays, so if
   %     any filtering is applied prior to passing in the arrays, the data needs
   %     to be used in subsequent functions or the indices won't be correct
   %
   %% Required inputs
   %
   %     T     time, nx1 vector of datetimes or datenums
   %     Q     flow, nx1 vector of discharge (length/time) (assumed m3/day/day)
   %     R     rain, nx1 vector of rainfall (length/time) (assumed mm/day)
   %
   %% Optional name-value inputs
   %
   %     opts        (optional) structure containing the following fields:
   %     qmin        minimum flow value, below which values are set nan
   %     nmin        minimum event length
   %     fmax        maximum # of missing values gap-filled
   %     rmax        maximum run of sequential constant values
   %     rmin        minimum rainfall required to censor flow (mm/day?)
   %     cmax        maximum run of sequential convex dQ/dt values
   %     rmconvex    remove convex derivatives
   %     rmnochange  remove consecutive constant derivates
   %     rmrain      remove rainfall
   %     pickevents  option to manually pick events
   %     plotevents  option to plot picked events
   %
   % Note: either the 'opts' struct can be provided with the
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
   %
   % See also: fitevents, eventfinder, eventsplitter, eventpicker, eventplotter
   %
   % Note: For data-heavy workflows, replace the Events output struct with the
   % eventTags list. The Events struct includes the input data and the event
   % data for convenience, but the event data can be easily extracted from the
   % input data using the eventTags.

   %% Main function

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [qmin, nmin, fmax, rmax, rmin, ~, rmconvex, rmnochange, rmrain, ...
      pickevents, plotevents, asannual, T, Q, R] = parseinputs(mfilename, ...
      T, Q, R, varargin{:});

   % save the input data
   Events.inputTime = T;
   Events.inputFlow = Q;
   Events.inputRain = R;

   % iF is the first non-nan index, to recover indices after removing nans
   numdata     = numel(T);
   Q(Q<qmin)   = nan;                     % set values < qmin nan
   Q           = setconstantnan(Q,rmax);  % set constant non-nan values nan
   [T,Q,R,iF]  = rmleadingnans(T,Q,R);    % remove leading nans
   [T,Q,R]     = rmtrailingnans(T,Q,R);   % remove trailing nans
   Q           = fillnans(Q,fmax);        % gap fill missing values

   % If events are detected on an annual basis, option to smooth measurement
   % noise. If multi-year timeseries are used, smoothing is not effective, there
   % is too much variability to select consistent smoothing parameters.
   if asannual
      Q = smoothflow(Q);
   end

   if isempty(Q) || ( sum(~isnan(Q)) < nmin ) % fast exit
      [t,q,r,Info] = setEventEmpty();
   else
      % call eventfinder either way, then update if pickfits == true
      [t,q,r,Info] = baseflow.eventfinder(T,Q,R, ...
         'nmin',        nmin,          ...
         'fmax',        fmax,          ...
         'rmax',        rmax,          ...
         'rmin',        rmin,          ...
         'rmconvex',    rmconvex,      ...
         'rmnochange',  rmnochange,    ...
         'rmrain',      rmrain         );

      Info = updateinfo(Info,iF,numdata);

      % NOTE: eventpicker doesn't update Info for events that are picked
      % within an eventfinder event, but only Info.istart is used in the
      % main algorithm so it is sufficient at this point
      if pickevents == true
         [t,q,r,Info] = baseflow.eventpicker(T,Q,R,nmin,Info);
      elseif plotevents == true
         % Info.hEvents = baseflow.eventplotter(T,Q,R,Info,'plotevents',plotevents);
      end
   end

   % if asannual == false
   [ ...
      Events.eventTime, ...
      Events.eventFlow, ...
      Events.eventRain, ...
      Events.eventTags] = flattenevents(t,q,r,Info);
   % end
end

function Info = updateinfo(Info,ifirst,numdata)

   fields = fieldnames(Info);

   for m = 1:numel(fields)
      Info.(fields{m}) = Info.(fields{m}) + ifirst - 1;
   end

   Info.runlengths   = Info.istop - Info.istart + 1;
   Info.ifirst       = ifirst;
   Info.datalength   = numdata;
end

%% INPUT PARSER
function [qmin, nmin, fmax, rmax, rmin, cmax, rmconvex, rmnochange, rmrain, ...
      pickevents, plotevents, asannual, T, Q, R] = parseinputs(mfilename, ...
      T, Q, R, varargin)

   persistent parser
   if isempty(parser)
      parser = inputParser;
      parser.StructExpand = true;
      parser.KeepUnmatched = true;
      % parser.PartialMatching = false;
      parser.CaseSensitive = true;

      parser.addRequired('T', @isdatelike);
      parser.addRequired('Q', @isnumeric);
      parser.addRequired('R', @isnumeric);

      parser.addParameter('qmin', 1, @isnumericscalar);
      parser.addParameter('nmin', 4, @isnumericscalar);
      parser.addParameter('fmax', 2, @isnumericscalar);
      parser.addParameter('rmax', 2, @isnumericscalar);
      parser.addParameter('rmin', 0, @isnumericscalar);
      parser.addParameter('cmax', 2, @isnumericscalar);
      parser.addParameter('rmconvex', false, @islogicalscalar);
      parser.addParameter('rmnochange', false, @islogicalscalar);
      parser.addParameter('rmrain', false, @islogicalscalar);
      parser.addParameter('pickevents', false, @islogicalscalar);
      parser.addParameter('plotevents', false, @islogicalscalar);
      parser.addParameter('asannual', false, @islogicalscalar);
   end
   parser.FunctionName = ['baseflow.' mfilename];
   parser.parse(T, Q, R, varargin{:});

   qmin = parser.Results.qmin;
   nmin = parser.Results.nmin;
   fmax = parser.Results.fmax;
   rmax = parser.Results.rmax;
   rmin = parser.Results.rmin;
   cmax = parser.Results.cmax;
   rmrain = parser.Results.rmrain;
   rmconvex = parser.Results.rmconvex;
   rmnochange = parser.Results.rmnochange;
   pickevents = parser.Results.pickevents;
   plotevents = parser.Results.plotevents;
   asannual = parser.Results.asannual;

   % Convert datetime to double if datetime was passed in
   T = todatenum(T);

   % Require T and Q same size but allow empty R (syntax: getevents(T,Q,[],...) )
   validateattributes(T, {'double'}, {'size', size(Q)}, mfilename, 'T', 1)
   validateattributes(nmin, {'double'}, {'>', 2}, mfilename, 'nmin', 4)
   if isempty(R)
      R = zeros(size(Q));
   end
end
