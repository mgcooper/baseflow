function tf = islogicalvector(x)
   tf = islogical(x) && isvector(x);
end