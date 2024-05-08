function N = numevents(EventData)
   %NUMEVENTS Count the number of events in EventData returned by baseflow.getevents
   %
   %  N = numevents(EventData)
   %
   % See also: numfits
   if isfield(EventData, 'eventTag')
      N = numel(unique(EventData.eventTag(~isnan(EventData.eventTag))));
   elseif isfield(EventData, 'eventTags')
      N = numel(unique(EventData.eventTags(~isnan(EventData.eventTags))));
   end
end
