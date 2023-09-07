function fullpath = docspath(docname, varargin)
   %DOCSPATH Return toolbox docs path.
   if isfile(fullfile(basepath(), 'docs', 'html', [docname '.html']))
      % help pages documentation
      fullpath = fullfile(basepath(), 'docs', 'html', [docname '.html']);
      
   elseif isfile(fullfile(basepath(), ...
         'docs', 'html', 'm2html', '+bfra', [docname '.html']))
      % function documentation
      
      fullpath = fullfile(basepath(), ...
         'docs', 'html', 'm2html', '+bfra', [docname '.html']);
   end
end