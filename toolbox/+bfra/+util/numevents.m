function N = numevents(Events)
   %NUMEVENTS Count the number of events in struct returned by bfra.getevents.
   N = numel(unique(Events.eventTags(~isnan(Events.eventTags))));
end
