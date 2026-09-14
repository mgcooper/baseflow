function tf = isdoublescalar(x)
   %ISDOUBLESCALAR Return true if input X is a double scalar.
   %
   %  tf = isdoublescalar(x) returns true if x is class double and scalar.
   tf = isa(x,'double') && isscalar(x);
end
