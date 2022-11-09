function tf = isdoublescalar(x)
   tf = isa(x,'double') && isscalar(x);