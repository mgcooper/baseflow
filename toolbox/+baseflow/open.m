function open(varargin)
   %OPEN Open package namespace function file in the MATLAB Editor.
   narginchk(1,1)
   funcname = validatestring(varargin{1}, bfra.internal.completions('open'));
   open(['bfra.' funcname])
   
   % note, this would also work to open help pages, if it is desirable to
   % collapse the two functions into one. But see bfra.completions for where I
   % restrict the available options for this function to top-level +bfra/
   % function files
   % bfra.help(funcname)
end