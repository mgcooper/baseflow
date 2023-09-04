function [T,Q,R,Info] = eventfinder(t,q,r,varargin)
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
   [t, q, r, nmin, fmax, rmax, rmin, rmconvex, rmnochange, rmrain] = ...
      parseinputs(t, q, r, mfilename, varargin{:});

   % MAIN CODE
   iS = unique([1; find(diff(isnan(q)) == -1)+1]);    % start non-nan segments
   iE = unique([find(diff(isnan(q)) == 1);numel(q)]); % end non-nan segments
   L  = iE - iS + 1;                                  % segment lengths

   % Remove events shorter than nmin
   iS = iS(L >= nmin);
   iE = iE(L >= nmin);

   % initialize the combined events
   [T, Q, R, Info] = deal(cell(numel(iS), 1));
         
   for n = 1:numel(iS)

      [T{n}, Q{n}, R{n}, Info{n}] = bfra.eventsplitter( ...
         t(iS(n):iE(n)), q(iS(n):iE(n)), r(iS(n):iE(n)), ...
         'nmin', nmin, ...
         'fmax', fmax, ...
         'rmax', rmax, ...
         'rmin', rmin, ...
         'rmrain', rmrain, ...
         'rmconvex', rmconvex, ...
         'rmnochange', rmnochange);
   end
   
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
   T = vertcat(T{:});
   Q = vertcat(Q{:});
   R = vertcat(R{:});
   Info = catstructfields(1, Info{:});
end

%% INPUT PARSER
function [t, q, r, nmin, fmax, rmax, rmin, rmconvex, rmnochange, rmrain] = ...
      parseinputs(t, q, r, funcname, varargin)

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

   nmin        = parser.Results.nmin;
   fmax        = parser.Results.fmax;
   rmax        = parser.Results.rmax;
   rmin        = parser.Results.rmin;
   rmconvex    = parser.Results.rmconvex;
   rmnochange  = parser.Results.rmnochange;
   rmrain      = parser.Results.rmrain;

   % Convert datetime to double if datetime was passed in
   t = todatenum(t);

   validateattributes(t, {'double'},{'size', size(q)}, funcname,'t', 1)
   validateattributes(nmin, {'double'},{'>', 2}, funcname,'nmin')

   % Allow empty r i.e. input syntax eventfinder(t,q,[],...)
   if isempty(r)
      r = zeros(size(t));
   end

   % Convert to columns, in case this is not called from bfra.getevents
   t = t(:);
   q = q(:);
   r = r(:);
end