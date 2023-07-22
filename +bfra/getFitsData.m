function Data = getFitsData(Fits,eventTag)
%GETFITSDATA get data from Fits for event number eventTag
% 
% Description
% 
% 
% 
% 
% 
% See also

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