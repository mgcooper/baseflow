function tf = isnumericscalar(x)
   %ISNUMERICSCALAR Return true if input X is a numeric scalar.
   tf = isnumeric(x) && isscalar(x);
end