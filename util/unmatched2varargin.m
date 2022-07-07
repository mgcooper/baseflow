function varargs = unmatched2varargin(unmatched)
   
   % convert unmatched to varargin
   fields   = fieldnames(unmatched);
   varargs  = {};
   for n = 1:numel(fields)
      varargs{2*n-1}  = fields{n};
      varargs{2*n}    = unmatched.(fields{n});
   end