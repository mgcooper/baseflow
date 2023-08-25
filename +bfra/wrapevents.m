function [Events] = wrapevents(T,Q,R,varargin)
%WRAPEVENTS wrapper around bfra.getevents to get recession all recession events
%for a mulit-year timeseries of T, Q, and R on an annual basis rather than for
%all dates in the raw timeseries. NOTE: deprecated, needs updating with new
%Events=bfra.getevents(...) syntax. Previously bfra.getevents, before the need
%for this was eliminated by adding call to flattenevents to bfra.findevents and
%renaming bfra.findevents to bfra.getevents. 
%
% 
% Required inputs:
%   T          =  nx1 array of dates
%   Q          =  nxm array of daily flow in units m3/day, organized as calendar
%                 years, meaning n/365 = # of years
%   R          =  nxm array of daily rainfall in (mm/day?)
% 
% Optional name-value inputs:
%  qmin        =  minimum flow value, below which values are set nan
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmin        =  minimum rainfall required to censor flow
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
% 
%  opts        =  structure containing the fields listed above, in lieu of
%                 entering them individually
% 
% Note: flow comes in as m3/day/day
% 
% See also findevents
% 
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end


% PARSE INPUTS
[qmin, nmin, fmax, rmax, rmin, cmax, rmconvex, rmnochange, rmrain, ...
   pickevents, plotevents, asannual, T, Q, R] = parseinputs( ...
   T, Q, R, mfilename, varargin{:});

% re-build opts to send to bfra.findevents
opts.qmin         = qmin;
opts.nmin         = nmin;
opts.fmax         = fmax;
opts.rmax         = rmax;
opts.rmin         = rmin;
opts.cmax         = cmax;
opts.rmconvex     = rmconvex;
opts.rmnochange   = rmnochange;
opts.rmrain       = rmrain;
opts.plotevents   = plotevents;
opts.pickevents   = pickevents;
opts.asannual     = asannual;

% do some input checks
[T,Q,R,numyears] = prepinput(T,Q,R);

% save the input data
Events.inputTime = T;
Events.inputFlow = Q;
Events.inputRain = R;

% number of timesteps per year
numsteps = size(Q,1)/numyears;

% reshape the input lists to matrices
if mod(numyears,1) == 0
   Qmat = reshape(Q,numsteps,numyears);    % flow, one column each year
   Rmat = reshape(R,numsteps,numyears);    % rain, one column each year
   Tmat = reshape(T,numsteps,numyears);    % calendar, one column each year
else
   % assume data is already in matrix form
   Qmat = Q;
   Rmat = R;
   Tmat = T;
end

% initialize output structure and output arrays
Qsave = nan(size(Qmat));
Rsave = nan(size(Qmat));
tsave = nan(size(Qmat));
Etags = nan(size(Qmat));
Count = 0; % initialize event counter

%------------------------------------------------------------------------------
% compute the recession constants
%------------------------------------------------------------------------------

for thisYear = 1:numyears      % events for this year at this gage

   if all(isnan(Qmat(:,thisYear)))
      continue;
   end

   thisYearTime = Tmat(:,thisYear);
   thisYearFlow = Qmat(:,thisYear);
   thisYearRain = Rmat(:,thisYear);

   % detect events for this year
   %[T,Q,R,Info] = bfra.findevents(thisYearTime,thisYearFlow,thisYearRain,opts);
   [allEvents,Info] = bfra.getevents(thisYearTime,thisYearFlow,thisYearRain,opts);

   % for each event, compute q,dqdt with each derivative
   numEvents = numel(Info.istart);

   for thisEvent = 1:numEvents

      % % if using findevents
      %eventQ = Q{thisEvent};
      %eventT = T{thisEvent};
      %eventR = R{thisEvent};
      
      % get the start/end index on the year calendar
      si = Info.istart(thisEvent);
      ei = Info.istop(thisEvent);
      
      eventQ = allEvents.eventFlow(si:ei);
      eventT = allEvents.eventTime(si:ei);
      eventR = allEvents.eventRain(si:ei);

      % if no flow was returned, continue
      if all(isnan(eventQ)); continue; else
         Count = Count+1;
      end

      % collect all data for the point-cloud
      Qsave( si:ei,thisYear ) = eventQ;
      Rsave( si:ei,thisYear ) = eventR;
      tsave( si:ei,thisYear ) = eventT;
      Etags( si:ei,thisYear ) = Count;
   end

   % pause to look at the fits
   if plotevents == true
      sprintf('all events fitted for %d',thisYear); pause; close all
   end
end

[ndays,numyears] = size(Qsave);
Events.eventTime = reshape(tsave, ndays*numyears, 1);
Events.eventFlow = reshape(Qsave, ndays*numyears, 1);
Events.eventRain = reshape(Rsave, ndays*numyears, 1);
Events.eventTags = reshape(Etags, ndays*numyears, 1);

% % convert to timetable and add units
% units = ["m3 d-1","mm d-1","days","m3 d-1","mm d-1","m3 d-2","m3 d-1","-"];
% Events = struct2timetable(Events,'VariableUnits',units);

%==========================================================================

function [T,Q,R,numyears] = prepinput(T,Q,R)
% PREPINPUT remove leap inds and determine number of years.

leapidx = month(T)==2 & day(T)==29;
T(leapidx) = []; 
Q(leapidx) = []; 
R(leapidx) = [];
numyears = numel(T)/365;

assert(numyears == round(numyears), 'complete annual timeseries required');

%% INPUT PARSER
function [qmin, nmin, fmax, rmax, rmin, cmax, rmconvex, rmnochange, rmrain, ...
   pickevents, plotevents, asannual, T, Q, R] = parseinputs(T, Q, R, ...
   mfilename, varargin)

parser = inputParser;
parser.FunctionName = ['bfra.' mfilename];
parser.StructExpand = true;

parser.addRequired('T', @(x) isnumeric(x) | isdatetime(x));
parser.addRequired('Q', @(x) isnumeric(x) & numel(x)==numel(T));
parser.addRequired('R', @isnumeric);

parser.addParameter('qmin', 1, @bfra.validation.isnumericscalar);
parser.addParameter('nmin', 4, @bfra.validation.isnumericscalar);
parser.addParameter('fmax', 2, @bfra.validation.isnumericscalar);
parser.addParameter('rmax', 2, @bfra.validation.isnumericscalar);
parser.addParameter('rmin', 0, @bfra.validation.isnumericscalar);
parser.addParameter('cmax', 2, @bfra.validation.isnumericscalar);
parser.addParameter('rmconvex', false, @islogical);
parser.addParameter('rmnochange', true, @islogical);
parser.addParameter('rmrain', false, @islogical);
parser.addParameter('pickevents', false, @islogical);
parser.addParameter('plotevents', false, @islogical);
parser.addParameter('asannual', false, @islogical);

parser.parse(T, Q, R, varargin{:});

qmin = parser.Results.qmin;
nmin = parser.Results.nmin;
fmax = parser.Results.fmax;
rmax = parser.Results.rmax;
rmin = parser.Results.rmin;
cmax = parser.Results.cmax;
rmrain = parser.Results.rmrain;
asannual = parser.Results.asannual;
rmconvex = parser.Results.rmconvex;
rmnochange = parser.Results.rmnochange;
pickevents = parser.Results.pickevents;
plotevents = parser.Results.plotevents;

if isempty(R)
   R = zeros(size(Q));
end

% Convert datetime to double if datetime was passed in
T = todatenum(T);