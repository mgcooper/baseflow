function open(varargin)
   %OPEN Open package namespace function file in the Editor.
   narginchk(1,1)
   funcname = validatestring(varargin{1}, baseflow.internal.completions('open'));

   edit(fullfile(baseflow.internal.buildpath('+baseflow'), funcname))
end

