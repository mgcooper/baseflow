
fields = fieldnames(Events);
for n = 1:numel(fields)
   thisfield = fields{n};
   Data.(thisfield) = Events.(thisfield)(row,col);
end