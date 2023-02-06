function Data = getEventsData(Events,eventTag)
%GETEVENTDATA get data from Events for event number eventTag
% 
% Description
% 
% 
% 
% 
% 
% See also



% this allows a column vector of tags instead of a reshaped matrix
if all(size(Events.Q)==size(Events.T)) && all(size(Events.Q) == size(Events.tag))
   row = find(Events.tag==eventTag);
   col = 1;
else
   [row,col] = find(Events.tag==eventTag);
end

fields = fieldnames(Events);
for n = 1:numel(fields)
   thisfield = fields{n};
   Data.(thisfield) = Events.(thisfield)(row,col);
end