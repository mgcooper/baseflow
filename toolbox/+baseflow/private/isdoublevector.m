function tf = isdoublevector(x)
   %ISDOUBLEVECTOR Return true if input X is a double vector.
   tf = isa(x,'double') && isvector(x);
end
