function N = numfits(EventFits)
   %NUMFITS Count the number of fits in EventFits returned by baseflow.fitevents
   %
   %  N = numfits(FitsData)
   %
   % See also: numevents
   if isfield(EventFits, 'eventTag')
      N = numel(unique(EventFits.eventTag(~isnan(EventFits.eventTag))));
   elseif isfield(EventFits, 'eventTags')
      N = numel(unique(EventFits.eventTags(~isnan(EventFits.eventTags))));
   end
end
