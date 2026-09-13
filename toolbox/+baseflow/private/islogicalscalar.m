function tf = islogicalscalar(x)
   %ISLOGICALSCALAR Return true if input X is a logical scalar.
   %
   %  tf = islogicalscalar(x) returns true if x is logical and scalar.
   tf = islogical(x) && isscalar(x);
end