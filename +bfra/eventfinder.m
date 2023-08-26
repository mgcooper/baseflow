function [T,Q,R,Info] = eventfinder(t,q,r,varargin)
%EVENTFINDER find recession events on hydrograph timeseries t,q and rainfall r
%
% Syntax
%
%     [T,Q,R,Info] = eventfinder(t,q,r,varargin)
%
% Description
%
%     [T,Q,R,Info] = eventfinder(t,q,r) Detects periods of declining flow on
%     hydrographs defined by inputs time 't', discharge 'q', and rainfall 'r'.
%     Use optional inputs to set parameters that determine how events are
%     identified.
%
% Required inputs
%
%     t           time
%     q           flow (m3/time)
%     r           rain (mm/time)
%
% Optional name-value inputs
%
%     nmin        minimum event length
%     fmax        maximum # of missing values gap-filled
%     rmax        maximum run of sequential constant values
%     rmin        minimum rainfall required to censor flow (mm/day?)
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
iS = [1;find(diff(isnan(q))==-1)+1];       % start non-nan segments
iE = [find(diff(isnan(q))==1);length(q)];  % end non-nan segments
L  = iE-iS+1;                              % segment lengths

% initialize the combined events
T = []; Q = []; R = []; Info = struct; iflag = false;

for n = 1:length(iS)
   
   if L(n)<nmin                       % set nan if <nmin
      [Tn,Qn,Rn,Infon] = setEventEmpty();
   else
      tn = t(iS(n):iE(n));
      qn = q(iS(n):iE(n));
      rn = r(iS(n):iE(n));
      
      [Tn,Qn,Rn,Infon] = bfra.eventsplitter( ...
         tn,qn,rn, ...
         'nmin', nmin, ...
         'fmax', fmax, ...
         'rmax', rmax, ...
         'rmin', rmin, ...
         'rmrain', rmrain, ...
         'rmconvex', rmconvex, ...
         'rmnochange', rmnochange);
   end
   
   % if no events were detected, Infon.istart will be empty
   if all(isempty(Infon.istart)); continue; else
      
      % iS is the start of the entire flow segment, but the indices in
      % Info are relative to the event returned by segmentevents. here
      % we add iS to these indices, except runlengths
      fields = fieldnames(Infon);
      
      if numel(Infon.ikeep) > 0
         
         for m = 1:numel(fields)
            Infon.(fields{m}) = Infon.(fields{m}) + iS(n) - 1;
         end
         
         % add the first non-nan index and runlengths to Info
         % Infon.ifirst = opts.ifirst;
         % Infon.runlengths = Infon.istop - Infon.istart + 1;
      end
      
      % this is needed b/c 'info' has no fieldnames until first detected event
      if iflag == false           % no events detected yet
         T = Tn; Q = Qn; R = Rn; Info = Infon; iflag = true;
         continue
      else                        % at least one detected event
         T = [T;Tn];
         Q = [Q;Qn];
         R = [R;Rn];
         Info = catstructfields(1,Info,Infon);
      end
   end
end

% if no events were returned, set events empty
if isempty(fieldnames(Info))
   [T,Q,R,Info] = setEventEmpty();
   
else % cycle through and remove empty events
   inan = false(size(T));
   for n = 1:numel(T)
      if isempty(T{n})
         inan(n) = true;
      end
   end
   T = T(~inan);
   Q = Q(~inan);
   R = R(~inan);
   
   Info.istart = Info.istart(~inan);
   Info.istop  = Info.istop(~inan);
   % Info.runlengths = Info.runlengths(~inan);
end

%% INPUT PARSER

function [t, q, r, nmin, fmax, rmax, rmin, rmconvex, rmnochange, rmrain] = ...
   parseinputs(t, q, r, funcname, varargin)

persistent parser
if isempty(parser)
   parser = inputParser;
   addRequired(parser, 't',                  @bfra.validation.isdatelike);
   addRequired(parser, 'q',                  @bfra.validation.isdoublevector);
   addRequired(parser, 'r',                  @isnumeric);
   addParameter(parser,'nmin',        4,     @bfra.validation.isnumericscalar);
   addParameter(parser,'fmax',        2,     @bfra.validation.isnumericscalar);
   addParameter(parser,'rmax',        2,     @bfra.validation.isnumericscalar);
   addParameter(parser,'rmin',        0,     @bfra.validation.isnumericscalar);
   addParameter(parser,'rmconvex',    false, @bfra.validation.islogicalscalar);
   addParameter(parser,'rmnochange',  false, @bfra.validation.islogicalscalar);
   addParameter(parser,'rmrain',      false, @bfra.validation.islogicalscalar);
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

% allow empty r i.e. input syntax eventfinder(t,q,[],...)
if isempty(r)
   r = zeros(size(t));
end

% convert to columns, in case this is not called from bfra.getevents
t = t(:);
q = q(:);
r = r(:);

% parser.Results includes all arguments, i.e., required, optional, and
% parameters, and orders the fields alphabetically, so its more trouble than its
% worth to use the simpler dealout syntax, which would require alphabetical
% assignment lists, but for reference:
% [fmax,nmin,q,r,rmax,rmconvex,rmin,rmnochange,rmrain,t] = ...
%    dealout(parser.Results);