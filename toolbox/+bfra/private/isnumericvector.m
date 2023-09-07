function tf = isnumericvector(x)
   %ISNUMERICVECTOR Return true if input X is a numeric vector.
   tf = isnumeric(x) && isvector(x);
end