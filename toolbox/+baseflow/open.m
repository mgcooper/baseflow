function open(varargin)
   %OPEN Open package namespace function file in the Editor.
   %
   % Syntax
   %
   %     baseflow.open(funcname)
   %
   % Description
   %
   %     baseflow.open(funcname) opens the file funcname.m from the
   %     +baseflow package folder in the Editor. funcname must match a name
   %     in the package completion list.
   %
   % See also: baseflow.help
   narginchk(1,1)
   funcname = validatestring(varargin{1}, baseflow.internal.completions('open'));

   edit(fullfile(baseflow.internal.buildpath('+baseflow'), funcname))
end

