function N = numevents(Events)

N = numel(unique(Events.tag(~isnan(Events.tag))));