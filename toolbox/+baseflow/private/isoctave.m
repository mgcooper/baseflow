function tf = isoctave()
%ISOCTAVE return true if the environment is Octave.
%
%  tf = isoctave() returns true when the OCTAVE_VERSION builtin exists.
%  A persistent variable caches the result to speed up repeated calls.

  persistent cacheval;  % speeds up repeated calls

  if isempty (cacheval)
    cacheval = (exist ("OCTAVE_VERSION", "builtin") > 0);
  end

  tf = cacheval;
  
end
