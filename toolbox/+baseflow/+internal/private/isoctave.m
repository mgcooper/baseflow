function tf = isoctave()
   %ISOCTAVE return true if the environment is Octave.
   %
   %
   % See also

   persistent cacheval

   if isempty (cacheval)
      cacheval = (exist ("OCTAVE_VERSION", "builtin") > 0);
   end
   tf = cacheval;
end
