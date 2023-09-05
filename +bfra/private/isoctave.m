function tf = isoctave()
%ISOCTAVE return TF = true if the environment is Octave.

  persistent cacheval;  % speeds up repeated calls

  if isempty (cacheval)
    cacheval = (exist ("OCTAVE_VERSION", "builtin") > 0);
  end

  tf = cacheval;
  
end
