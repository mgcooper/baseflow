function proplist = completions(funcname)
%COMPLETIONS Generate function auto-completions for string literals.
switch lower(funcname)
   
   case 'completions'
      
      % To generate a completions list of all functions in +bfra folder:
      % tmp = dir(fullfile(basepath(), '+bfra', '*.m'));
      % proplist = strrep({tmp.name}, '.m', '');
      
      % To hard-code them using all members of the case set below:
      proplist = {'help', 'open', 'private'};
      
   case 'help'
      tmp = dir(fullfile(basepath(), 'docs', '**/*.html'));
      proplist = strrep({tmp.name}, '.html', '');
      
   case 'open'
      tmp = dir( ...
         ... fullfile(basepath(), '+bfra', '**/*.m'));
         fullfile(basepath(), '+bfra', '*.m')); % restrict to +bfra files
      proplist = strrep({tmp.name}, '.m', '');
      
   case 'private'
      tmp = dir(fullfile(basepath(), '+bfra', 'private', '*.m'));
      proplist = strrep({tmp.name}, '.m', '');
end
