function N = numtau(Fits)
   %NUMTAU Count the number of tau values in struct returned by baseflow.fitevents.
   N = numel(Fits.eventTags(~isnan(Fits.eventTags)));
end
