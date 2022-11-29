function N = numfits(Fits)

N = numel(unique(Fits.eventTag(~isnan(Fits.eventTag))));