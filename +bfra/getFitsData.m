
fields = fieldnames(Fits);
for n = 1:numel(fields)
   thisfield = fields{n};
   Data.(thisfield) = Fits.(thisfield)(row,col);
end