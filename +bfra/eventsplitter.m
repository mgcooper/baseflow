function [T,Q,R,Info] = eventsplitter(t,q,r,varargin)
%eventsplitter split detected recession events into useable segments for fitting
%
% Syntax
%
%     [T,Q,R,Info] = eventsplitter(t,q,r,varargin)
%
% Description
%
%     Split recession events detected by eventfinder into individual segments
%     ready to fit with bfra.fitab or bfra.fitevents. For example, if an event
%     is interrupted by rainfall or if rainfall is detected from convex dq/dt,
%     the event can be split into separate segments thought to represent
%     uninterrupted baseflow.
%
% Required inputs
%
%     t        time
%     q        flow (m3/time)
%     r        rain (mm/time)
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
% See also getevents, eventfinder, eventpicker, eventplotter
%
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

persistent inoctave
if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
end

% if nmin is set to 0 (and maybe if it is set to 1) this method will fail
% because runlength returns 1 for consecutive nan values, see isminlength.

% PARSE INPUTS
[t, q, r, nmin, ~, rmax, rmin, rmconvex, rmnochange, rmrain] = parseinputs( ...
   t, q, r, mfilename, varargin{:});
debug = false;

% MAIN CODE (follows recommendations in Dralle et al. 2017)

% get a 3-day smoothed timeseries to control false positive convexity
if inoctave
   qS = bfra.util.nanmovmean(q,3);
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
if rmconvex == true
   ibad = [ibad; icon];
   if rmrain == false
      ibad = [ibad; icon2]; % substitute for lack of rain data
   end
end

% exclude days with rain > rmin and convex recession
% also exclude 3 days before/after and combine with ibad
if rmrain == true
   irain = find(r > rmin);
   irain = unique([irain; irain+1; irain-1; irain+2; irain-2; irain+3; irain-3]);
   irain = irain(ismember(irain, icon2));
   ibad  = [ibad; irain];
end

% exclude sequences of two or more of (dq/dt = 0) (see setconstantnan)
if rmnochange == true
   inoc = d2qdt; inoc(inoc ~= 0) = nan;
   inoc = find(bfra.util.isminlength(inoc, rmax));
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
[tfk,is,ie] = bfra.util.isminlength(tfk, nmin); 
eventlength = ie - is + 1; % event (run) lengths

% pull out the events
N = numel(is);
T = cell(N, 1);
Q = cell(N, 1);
R = cell(N, 1);

% apply min length filter and keep remaining events
for n = 1:N

   % if event length < min length, ignore it
   if eventlength(n) < nmin
      N = N-1;
      continue
   end
   qi = q(is(n):ie(n));
   if bfra.util.islineconvex(qi) || bfra.util.islinepositive(qi)
      N = N-1;
      continue
   end

   T{n} = t(is(n):ie(n));
   Q{n} = q(is(n):ie(n));
   R{n} = r(is(n):ie(n));

end

% return events that passed the nmin filter
if N > 0
   Info.imaxima    = imax;
   Info.iminima    = imin;
   Info.iconvex    = icon;
   Info.icandidate = find(tfc);
   Info.ikeep      = find(tfk);
   Info.istart     = is;
   Info.istop      = ie;
else
   [T,Q,R,Info] = setEventEmpty;
end

% debug plot:
if debug == true
   figure; plot(t, q); hold on; plot(t, qS, 'g');
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

function tf = islocalmax(X)
tf = false(size(X));
tf(bfra.deps.peakfinder(X,0,0,1,false)) = true;

function tf = islocalmin(X)
tf = false(size(X));
tf(bfra.deps.peakfinder(X,0,0,-1,false)) = true;

%% INPUT PARSER

function [t, q, r, nmin, fmax, rmax, rmin, rmconvex, rmnochange, rmrain] = ...
   parseinputs(t, q, r, funcname, varargin)

persistent parser
if isempty(parser)
   parser = inputParser;
   parser.FunctionName = funcname;
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
parse(parser,t,q,r,varargin{:});

nmin        = parser.Results.nmin;
fmax        = parser.Results.fmax;
rmax        = parser.Results.rmax;
rmin        = parser.Results.rmin;
rmconvex    = parser.Results.rmconvex;
rmnochange  = parser.Results.rmnochange;
rmrain      = parser.Results.rmrain;

validateattributes(t, {'double'},{'size', size(q)}, funcname,'t', 1)
validateattributes(nmin, {'double'},{'>', 2}, funcname,'nmin', 4)

% allow empty r i.e. input syntax eventsplitter(t,q,[],...)
if isempty(r)
   r = zeros(size(t));
end

% convert to columns, in case this is not called from bfra.getevents
t = t(:);
q = q(:);
r = r(:);
