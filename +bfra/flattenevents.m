function Events = flattenevents(t,q,r,T,Q,R,Info)
%FLATTENEVENTS flatten the cell arrays returned by findevents
% 
%  Inputs
%     T, Q, R : lists of time, streamflow, and rainfall 
%     t, q, r : cell arrays of events
% 
%  See also: getevents, findevents

% save the original lists
Events.T = T;
Events.Q = Q;
Events.R = R;
      
% initialize output structure and output arrays
numEvents   =  numel(Info.istart);
numData     =  Info.datalength;
Qsave       =  nan(numData,1);
Rsave       =  nan(numData,1);
% tsave       =  nan(numData,1);
tsave       =  NaT(numData,1);
tags        =  nan(numData,1);
eventCount  =  0;                      % initialize event counter

for thisEvent = 1:numEvents

   eventQ = q{thisEvent};
   eventT = t{thisEvent};
   eventR = r{thisEvent};

   % if no flow was returned, continue
   if all(isnan(eventQ)); continue; else
      eventCount = eventCount+1;
   end

   % get the start/end index on the year calendar
   si = Info.istart(thisEvent);
   ei = Info.istop(thisEvent);

   % collect all data for the point-cloud
   Qsave(si:ei) = eventQ;
   Rsave(si:ei) = eventR;
%    tsave(si:ei) = datenum(eventT);
   tsave(si:ei) = eventT;
   tags( si:ei) = eventCount; 
end

% overwrite the cell arays with flattened arrays
Events.t    = tsave;
Events.q    = Qsave;
Events.r    = Rsave;
Events.tag  = tags;

