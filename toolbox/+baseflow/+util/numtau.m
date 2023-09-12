function N = numtau(Fits)
   %NUMTAU Count the number of tau values in struct returned by bfra.fitevents.
   N = numel(Fits.eventTags(~isnan(Fits.eventTags)));
end
