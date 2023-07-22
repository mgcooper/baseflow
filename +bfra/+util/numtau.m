function N = numtau(Fits)

N = numel(Fits.eventTags(~isnan(Fits.eventTags)));