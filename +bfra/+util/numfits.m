function N = numfits(Fits)

N = numel(unique(Fits.eventTags(~isnan(Fits.eventTags))));