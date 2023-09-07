function tf = isdoublescalar(x)
   %ISDOUBLESCALAR Return true if input X is a double scalar.
   tf = isa(x,'double') && isscalar(x);
end
