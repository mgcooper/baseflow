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

% parse inputs
p = inputParser;
p.FunctionName = 'bfra.wrapevents';
p.StructExpand = true;

addRequired(p, 'T',                    @(x) isnumeric(x) | isdatetime(x)      );
addRequired(p, 'Q',                    @(x) isnumeric(x) & numel(x)==numel(T) );
addRequired(p, 'R',                    @(x) isnumeric(x)                      );
addParameter(p,'qmin',        1,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'nmin',        4,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'fmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmin',        0,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'cmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmconvex',    false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'rmnochange',  true,    @(x) islogical(x) & isscalar(x)        );
addParameter(p,'rmrain',      false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'pickevents',  false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'plotevents',  false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'asannual',    false,   @(x) islogical(x) & isscalar(x)        );

parse(p,T,Q,R,varargin{:});

qmin        = p.Results.qmin;
nmin        = p.Results.nmin;
fmax        = p.Results.fmax;
rmax        = p.Results.rmax;
rmin        = p.Results.rmin;
cmax        = p.Results.cmax;
rmconvex    = p.Results.rmconvex;
rmnochange  = p.Results.rmnochange;
rmrain      = p.Results.rmrain;
pickevents  = p.Results.pickevents;
plotevents  = p.Results.plotevents;
asannual    = p.Results.asannual;

if isempty(R); R = zeros(size(Q)); end
%------------------------------------------------------------------------------

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
tsave = NaT(size(Qmat)); % nan(size(Qmat)); % TEST
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
      tsave( si:ei,thisYear ) = eventT; % datenum(eventT); % TEST
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

function [T,Q,R,numyears,timestep] = prepinput(T,Q,R)
% PREPINPUT remove leap inds, determine timestep, determine number of years.

% NOTE: this is only needed for year-by-year analysis. findevents can be used on
% a timeseries of any length, and could then be flattened and reshaped to match
% some other calendar, rather than doing it first, as in getevents.

% convert T to datetime
if ~isdatetime(T); T = datetime(T,'ConvertFrom','datenum'); end

% check if the input data includes leap inds
hasleap = month(T)==2 & day(T)==29;

% if the time is regular, we can get the timestep here
if isregular(timetable(T,'RowTimes',T),'time')
   timestep = T(2)-T(1);
else
   % if leap inds are already removed, the time won't be regular, so only
   % warn if time includes leap inds
   if any(hasleap)
      warning('irregular calendar, results may be inconsistent')
   end
end

if any(hasleap)
   warning('removing leap inds');
   T(hasleap) = []; Q(hasleap) = []; R(hasleap) = [];
end

% this is correct
numyears = numel(T)/365;

% % both of these fail if water years are passed in   
% numyears = numel(unique(year(T)));
% 
% firstyear   = year(T(1));
% lastyear    = year(T(end));
% numyears    = lastyear-firstyear+1;