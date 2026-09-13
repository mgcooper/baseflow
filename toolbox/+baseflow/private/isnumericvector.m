function tf = isnumericvector(x)
   %ISNUMERICVECTOR Return true if input X is a numeric vector.
   %
   %  tf = isnumericvector(x) returns true if x is numeric and a vector.
   tf = isnumeric(x) && isvector(x);
end