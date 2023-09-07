function tf = islogicalvector(x)
   %ISLOGICALVECTOR Return true if input X is a logical vector.
   tf = islogical(x) && isvector(x);
end