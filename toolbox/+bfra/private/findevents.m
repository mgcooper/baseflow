function [t,q,r,Info] = findevents(T,Q,R,varargin)
   %FINDEVENTS returns flow Q and time T values of each individual recession event,
   %and info about the applied filters
   %
   % Required inputs:
   %  T           =  time
   %  Q           =  flow (m3/time)
   %  R           =  rain (mm/time)
   %
   % Optional name-value inputs:
   %  opts        =  (optional) structure containing the following fields:
   %  qmin        =  minimum flow value, below which values are set nan
   %  nmin        =  minimum event length
   %  fmax        =  maximum # of missing values gap-filled
   %  rmax        =  maximum run of sequential constant values
   %  rmin        =  minimum rainfall required to censor flow (mm/day?)
   %  cmax        =  maximum run of sequential convex dQ/dt values
   %  rmconvex    =  remove convex derivatives
   %  rmnochange  =  remove consecutive constant derivates
   %  rmrain      =  remove rainfall
   %  pickevents  =  option to manually pick events
   %  plotevents  =  option to plot picked events
   %
   % Tip: events are identified by their indices on the t,q,r arrays, so if
   % any filtering is applied prior to passing in the arrays, the data needs
   % to be used in subsequent functions or the indices won't be correct
   %
   %  See also: getevents, eventsplitter, eventpicker, eventplotter

   %% Main function

   % PARSE INPUTS
   [qmin, nmin, fmax, rmax, rmin, ~, rmconvex, rmnochange, rmrain, ...
      pickevents, plotevents, asannual, T, Q, R] = parseinputs(mfilename, ...
      T, Q, R, varargin{:});

   % iF is the first non-nan index, to recover indices after removing nans
   numdata     = numel(T);
   Q(Q<qmin)   = nan;                     % set values < qmin nan
   Q           = setconstantnan(Q,rmax);  % set constant non-nan values nan
   [T,Q,R,iF]  = rmleadingnans(T,Q,R);    % remove leading nans
   [T,Q,R]     = rmtrailingnans(T,Q,R);   % remove trailing nans
   Q           = fillnans(Q,fmax);        % gap fill missing values

   % smooth measurement noise
   if asannual
      Q = smoothflow(Q);
   end

   % % for reference, two other options I tested
   % [Q, win] = smoothnoise(Q, 'annual');  % smooth measurement noise
   % [Q, win] = smoothdata(Q, 'sgolay');  % smooth measurement noise

   if isempty(Q) || ( sum(~isnan(Q)) < nmin ) % fast exit
      [t,q,r,Info] = setEventEmpty();
   else
      % call eventfinder either way, then update if pickfits == true
      [t,q,r,Info] = bfra.eventfinder(T,Q,R, ...
         'nmin',        nmin,          ...
         'fmax',        fmax,          ...
         'rmax',        rmax,          ...
         'rmin',        rmin,          ...
         'rmconvex',    rmconvex,      ...
         'rmnochange',  rmnochange,    ...
         'rmrain',      rmrain         );

      Info = updateinfo(Info,iF,numdata);

      % for the window test
      % Info.winsize = win;

      % NOTE: eventpicker doesn't update Info for events that are picked
      % within an eventfinder event, but only Info.istart is used in the
      % main algorithm so it is sufficient at this point
      if pickevents == true
         [t,q,r,Info] = bfra.eventpicker(T,Q,R,nmin,Info);
      elseif plotevents == true
         Info.hEvents = bfra.eventplotter(T,Q,R,Info,'plotevents',plotevents);
      end
   end
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
      parser.PartialMatching = false;
      parser.CaseSensitive = true; % true because T,Q,R are sent back

      parser.addRequired('T',                  @(x) isnumeric(x) | isdatetime(x)     );
      parser.addRequired('Q',                  @(x) isnumeric(x) & numel(x)==numel(T));
      parser.addRequired('R',                  @(x) isnumeric(x)                     );

      parser.addParameter('qmin',        0,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('nmin',        4,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('fmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('rmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('rmin',        0,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('cmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
      parser.addParameter('rmconvex',    false, @(x) islogical(x) & isscalar(x)       );
      parser.addParameter('rmnochange',  false, @(x) islogical(x) & isscalar(x)       );
      parser.addParameter('rmrain',      false, @(x) islogical(x) & isscalar(x)       );
      parser.addParameter('pickevents',  false, @(x) islogical(x) & isscalar(x)       );
      parser.addParameter('plotevents',  false, @(x) islogical(x) & isscalar(x)       );
   end
   parser.FunctionName = ['bfra.' mfilename];
   parser.parse(T, Q, R, varargin{:});

   qmin        = parser.Results.qmin;
   nmin        = parser.Results.nmin;
   fmax        = parser.Results.fmax;
   rmax        = parser.Results.rmax;
   rmin        = parser.Results.rmin;
   cmax        = parser.Results.cmax;
   rmconvex    = parser.Results.rmconvex;
   rmnochange  = parser.Results.rmnochange;
   rmrain      = parser.Results.rmrain;
   pickevents  = parser.Results.pickevents;
   plotevents  = parser.Results.plotevents;
   
   asannual = true; % added to replicate getevents

   % Convert datetime to double if datetime was passed in
   T = todatenum(T);

   % Require T and Q same size but allow empty R (syntax: getevents(T,Q,[],...) )
   validateattributes(T, {'double'}, {'size', size(Q)}, mfilename, 'T', 1)
   validateattributes(nmin, {'double'}, {'>', 2}, mfilename, 'nmin', 4)
   if isempty(R)
      R = zeros(size(Q));
   end
end
