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

% NOTE: this function is only needed to enforce year-by-year analysis.
% findevents can be used on a timeseries of any length, but it will return
% events in cell arrays which can then be flattened and reshaped to match a
% regular calendar by bfra.flattenevents, rather than reshaping first here.
% HOWEVER, this function also calls bfra.getdqdt to get a first-order estimate
% of dqdt for quick plotting of a point cloud fit, for example. But, this should
% almost surely be eliminated, and the output of this function should be passed
% to fitdqdt independently of fitevents to get a quick dq/dt .

%------------------------------------------------------------------------------   
%------------------------------------------------------------------------------

p              = inputParser;
p.FunctionName = 'bfra.wrapevents';
p.StructExpand = true;

addRequired(p, 'T',                    @(x) isnumeric(x) | isdatetime(x)      );
addRequired(p, 'Q',                    @(x) isnumeric(x) & numel(x)==numel(T) );
addRequired(p, 'R',                    @(x) isnumeric(x)                      );
addParameter(p,'qmin',        0,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'nmin',        4,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'fmax',        1,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmin',        0,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'cmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
addParameter(p,'rmconvex',    false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'rmnochange',  true,    @(x) islogical(x) & isscalar(x)        );
addParameter(p,'rmrain',      false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'pickevents',  false,   @(x) islogical(x) & isscalar(x)        );
addParameter(p,'plotevents',  false,   @(x) islogical(x) & isscalar(x)        );

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

if isempty(R); R = zeros(size(Q)); end
%------------------------------------------------------------------------------

% % for now, re-build opts to send to bfra.findevents
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

% do some input checks
[T,Q,R,numyears]  = prepinput(T,Q,R);

% save the T,Q arrays in 'events'
Events.T    =  T;
Events.Q    =  Q;
Events.R    =  R;

% reshape the input lists to arrays (use of 'list' is a misnomer below)
numsteps = size(Q,1)/numyears;      % number of timesteps per year

if mod(numyears,1) == 0
   Qlist       =  reshape(Q,numsteps,numyears);    % flow, each year
   Rlist       =  reshape(R,numsteps,numyears);    % rain, each year
   Tlist       =  reshape(T,numsteps,numyears);    % calendar, each year
else
   % assume data is already in a list
   Qlist       =  Q;
   Rlist       =  R;
   Tlist       =  T;
end

% initialize output structure and output arrays
Qsave       =  nan(size(Qlist));
Rsave       =  nan(size(Qlist));
tsave       =  nan(size(Qlist));
dQsave      =  nan(size(Qlist));
qQsave      =  nan(size(Qlist));       % approximated flow
tags        =  nan(size(Qlist));
eventCount  =  0;                      % initialize event counter

%------------------------------------------------------------------------------
% compute the recession constants
%------------------------------------------------------------------------------

for thisYear = 1:numyears      % events for this year at this gage

   if all(isnan(Qlist(:,thisYear)))
      continue;
   end

   thisYearTime   = Tlist(:,thisYear);
   thisYearFlow   = Qlist(:,thisYear);
   thisYearRain   = Rlist(:,thisYear);

   % NEEDS TO BE UPDATED WITH NEW EVENTS = BFRA.GETEVENTS(...) SYNTAX
   % get events for this year
   [T,Q,R,Info]   = bfra.findevents(   thisYearTime,                 ...
                                       thisYearFlow,                 ...
                                       thisYearRain,                 ...
                                       opts                          );

   % for each event, compute q,dqdt with each derivative
   numEvents = numel(Info.istart);

   for thisEvent = 1:numEvents

      eventQ      = Q{thisEvent};
      eventT      = T{thisEvent};
      eventR      = R{thisEvent};

      % get approximated flow and dq/dt without any fitting of a/b
      [qQ,dQ]     = bfra.getdqdt(eventT,eventQ,eventR,'B1','pickmethod',...
                        'none','fitmethod','none'); 
      % if fitmethod == "none", only the dQdt is returned, for the case
      % where I don't wan't to fit events, so this function returns
      % everything needed to fit the distribution of qQ and dQ, i think

      % if no flow was returned, continue
      if all(isnan(eventQ)); continue; else
         eventCount = eventCount+1;
      end


      % get the start/end index on the year calendar
      si  = Info.istart(thisEvent);
      ei  = Info.istop(thisEvent);

      % collect all data for the point-cloud
      Qsave(  si:ei,thisYear)    =   eventQ;
      Rsave(  si:ei,thisYear)    =   eventR;
      dQsave( si:ei,thisYear)    =   dQ;
      qQsave( si:ei,thisYear)    =   qQ;
      tsave(  si:ei,thisYear)    =   datenum(eventT);
      tags(   si:ei,thisYear)    =   eventCount; 
      % eventCount tags events with index in K struct

   end

   % pause to look at the fits
   if plotevents == true
      sprintf('all events fitted for %d',thisYear); pause; close all
   end
end

[ndays,numyears]   =   size(Qsave);
Events.t       =   reshape(tsave, ndays*numyears, 1);
Events.q       =   reshape(Qsave, ndays*numyears, 1);
Events.r       =   reshape(Rsave, ndays*numyears, 1);
Events.dqdt    =   reshape(dQsave,ndays*numyears, 1);
Events.qq      =   reshape(qQsave,ndays*numyears, 1);
Events.tag     =   reshape(tags,  ndays*numyears, 1);

% % should convert to timetable and add units
% units = ["m3 d-1","mm d-1","days","m3 d-1","mm d-1","m3 d-2","m3 d-1","-"];
% Events = struct2timetable(Events,'VariableUnits',units);


%==========================================================================

function [T,Q,R,numyears,timestep] = prepinput(T,Q,R)
% PREPINPUT prepare input data - remove leap inds, determine timestep, determine
% number of years.

% NOTE: this is only needed if we want to enforce year-by-year analysis.
% findevents can be used on a timeseries of any length, and could then be
% flattened and reshaped to match some other calendar, rather than doing it
% first, as in getevents

% convert T to datetime
if ~isdatetime(T); T =  datetime(T,'ConvertFrom','datenum'); end

% check if the input data includes leap inds
hasleap = month(T)==2 & day(T)==29;

% if the time is regular, we can get the timestep here
test = timetable(T,'RowTimes',T);
if isregular(test,'time')
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