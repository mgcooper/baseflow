function [t,q,r,tags] = flattenevents(T,Q,R,Info)
%FLATTENEVENTS flatten the cell arrays returned by findevents
% 
%  Inputs
%     T, Q, R : lists of time, streamflow, and rainfall 
%     t, q, r : cell arrays of events
% 
%  See also: getevents, findevents
      
% initialize output structure and output arrays
nEvents  = numel(Info.istart);
nData    = Info.datalength;
q        = nan(nData,1);
r        = nan(nData,1);
t        = NaT(nData,1,'Format','dd-MMM-uuuu HH:mm:ss');
tags     = nan(nData,1);

eventCount = 0;                      % initialize event counter

for thisEvent = 1:nEvents

   eventQ = Q{thisEvent};
   eventT = T{thisEvent};
   eventR = R{thisEvent};

   % if no flow was returned, continue
   if all(isnan(eventQ)); continue; else
      eventCount = eventCount+1;
   end

   % get the start/end index on the year calendar
   si = Info.istart(thisEvent);
   ei = Info.istop(thisEvent);

   % collect all data for the point-cloud
   q(si:ei) = eventQ;
   r(si:ei) = eventR;
   t(si:ei) = eventT;   % datenum(eventT);
   tags(si:ei) = eventCount; 
end

