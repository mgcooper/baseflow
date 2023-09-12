function Data = getFitsData(Fits,eventTag)
   %GETFITSDATA Get data from Fits for event number eventTag.
   %
   %  Data = getFitsData(Fits,eventTag) returns the data in Fits struct
   %  returned by baseflow.fitevents for event tagged by EVENTTAG.
   %
   % See also: getEventsData

   % this allows a column vector of tags instead of a reshaped matrix
   if all(size(Fits.q)==size(Fits.t)) && all(size(Fits.q) == size(Fits.eventTags))
      row = find(Fits.eventTags==eventTag);
      col = 1;
   else
      [row,col] = find(Fits.eventTags==eventTag);
   end

   fields = fieldnames(Fits);
   for n = 1:numel(fields)
      thisfield = fields{n};
      Data.(thisfield) = Fits.(thisfield)(row,col);
   end
end