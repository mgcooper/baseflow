function [Events] = BFRA_Events(T,Q,R,varargin)
%BFRA_EVENTS get recession events.
% 
% This is basically a wrapper around bfra_getevents for multi-year
% timeseries. 
% 
% Inputs:
%   T    =  nx1 array of dates
%   Q    =  nxm array of daily flow in units m3/day, organized as calendar
%           years, meaning n/365 = # of years
%   R    =  nxm array of daily rainfall
%  opts  =  structure containing the following fields:
%  qmin        =  minimum flow value, below which values are set nan
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
   
% flow comes in as m3/day/day
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p = MipInputParser;
p.FunctionName = 'BFRA_Events';
p.StructExpand = true;
p.addRequired( 'T',                    @(x) isnumeric(x) | isdatetime(x)      );
p.addRequired( 'Q',                    @(x) isnumeric(x) & numel(x)==numel(T) );
p.addRequired( 'R',                    @(x) isnumeric(x)                      );
p.addParameter('qmin',        0,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('nmin',        4,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('fmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('rmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('rmin',        0,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('cmax',        2,       @(x) isnumeric(x) & isscalar(x)        );
p.addParameter('rmnochange',  true,    @(x) islogical(x) & isscalar(x)        );
p.addParameter('rmconvex',    false,   @(x) islogical(x) & isscalar(x)        );
p.addParameter('rmrain',      false,   @(x) islogical(x) & isscalar(x)        );
p.addParameter('pickevents',  false,   @(x) islogical(x) & isscalar(x)        );
p.addParameter('plotevents',  false,   @(x) islogical(x) & isscalar(x)        );
p.parseMagically('caller');
if isempty(R); R = zeros(size(Q)); end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% % for now, re-build opts to send to bfra_getevents
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
   
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% compute the recession constants
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   for thisYear = 1:numyears      % events for this year at this gage
      
      if all(isnan(Qlist(:,thisYear)))
         continue;
      end
      
      thisYearTime   = Tlist(:,thisYear);
      thisYearFlow   = Qlist(:,thisYear);
      thisYearRain   = Rlist(:,thisYear);
      
      % get events for this year
      [T,Q,R,Info]   = bfra_getevents(    thisYearTime,                 ...
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
         [qQ,dQ]     = bfra_getdqdt(eventT,eventQ,eventR,'B1','pickmethod',...
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
         tags(   si:ei,thisYear)    =   eventCount; % tag events with index in K struct
         
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
   
end

%==========================================================================

function [T,Q,R,numyears,timestep]  =  prepinput(T,Q,R)
   
   % convert T to datetime
   if ~isdatetime(T); T =  datetime(T,'ConvertFrom','datenum'); end
   
   % check if the input data includes leap inds
   hasleap = month(T)==2 & day(T)==29;
   
   % if the time is regular, we can get the timestep here
   test = timetable(T);
   if isregular(test,'time')
      timestep    =  T(2)-T(1);
   else
      % only warn if leap inds are not already missing
      if ~any(hasleap)
         warning('irregular calendar, results may be inconsistent')
      end
   end
   
   if any(hasleap)
      warning('removing leap inds');
      T(hasleap) = []; Q(hasleap) = []; R(hasleap) = [];
   end
   
   firstyear   = year(T(1));
   lastyear    = year(T(end));
   numyears    = lastyear-firstyear+1;
end