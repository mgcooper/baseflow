function tf = islogicalvector(x)
   %ISLOGICALVECTOR Return true if input X is a logical vector.
   %
   %  tf = islogicalvector(x) returns true if x is logical and a vector.
   tf = islogical(x) && isvector(x);
end