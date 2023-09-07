function tf = islogicalscalar(x)
   %ISLOGICALSCALAR Return true if input X is a logical scalar.
   tf = islogical(x) && isscalar(x);
end