function N = numfits(Fits)
   %NUMFITS Count the number of fits in struct returned by baseflow.fitevents.
   N = numel(unique(Fits.eventTags(~isnan(Fits.eventTags))));
end
