function Data = getEventsData(Events,eventTag)
   %GETEVENTSDATA get data from Events for event number eventTag
   %
   %  Data = getEventsData(Events,eventTag) returns the data in Events struct
   %  returned by bfra.getevents for event tagged by EVENTTAG.
   %
   % See also: getFitsData

   % this allows a column vector of tags instead of a reshaped matrix
   if all(size(Events.eventFlow)==size(Events.eventTime)) && ...
         all(size(Events.eventFlow) == size(Events.eventTags))
      row = find(Events.eventTags==eventTag);
      col = 1;
   else
      [row,col] = find(Events.eventTags==eventTag);
   end

   fields = fieldnames(Events);
   for n = 1:numel(fields)
      thisfield = fields{n};
      Data.(thisfield) = Events.(thisfield)(row,col);
   end
end
