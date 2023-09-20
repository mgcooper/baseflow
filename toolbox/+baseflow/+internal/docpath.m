function fullpath = docpath(docname, varargin)
   %DOCPATH Return path to toolbox doc file.
   
   docspath = fullfile(toolboxpath(), 'docs', 'html');
   
   if isfile(fullfile(docspath, [docname '.html']))
      % help pages documentation
      fullpath = fullfile(docspath, [docname '.html']);
      
   elseif isfile(fullfile(docspath, 'm2html', '+baseflow', [docname '.html']))
      % function documentation      
      fullpath = fullfile(docspath, 'm2html', '+baseflow', [docname '.html']);
   end
end
