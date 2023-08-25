function proplist = completions(funcname)
%COMPLETIONS function completions
switch lower(funcname)
   
   case 'completions'
      tmp = dir( ...
         fullfile(bfra.util.basepath, '+bfra', '*.m'));
      proplist = strrep({tmp.name}, '.m', '');
      
   case 'private'
      tmp = dir( ...
         fullfile(bfra.util.basepath, '+bfra', 'private', '*.m'));
      proplist = strrep({tmp.name}, '.m', '');
end
