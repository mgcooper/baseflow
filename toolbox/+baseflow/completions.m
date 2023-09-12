function proplist = completions(funcname)
   %COMPLETIONS Generate function auto-completions for string literals.
   switch lower(funcname)

      case 'completions'

         % To generate a completions list of all functions in +baseflow folder:
         % tmp = dir(fullfile(baseflow.internal.basepath(), '+baseflow', '*.m'));
         % proplist = strrep({tmp.name}, '.m', '');

         % To hard-code them using all members of the case set below:
         proplist = {'help', 'open', 'private'};

      case 'help'
         tmp = dir(fullfile(baseflow.internal.basepath(), 'docs', '**/*.html'));
         proplist = strrep({tmp.name}, '.html', '');

      case 'open'
         % restrict to +baseflow files
         tmp = dir(fullfile(baseflow.internal.basepath(), '+baseflow', '*.m'));
         proplist = strrep({tmp.name}, '.m', '');

      case 'private'
         tmp = dir(fullfile(baseflow.internal.basepath(), '+baseflow', 'private', '*.m'));
         proplist = strrep({tmp.name}, '.m', '');
   end
