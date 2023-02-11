function N = numevents(Events)

N = numel(unique(Events.eventTags(~isnan(Events.eventTags))));