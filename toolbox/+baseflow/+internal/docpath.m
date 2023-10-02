function fullpath = docpath(docname)
   %DOCPATH Return path to toolbox doc file.
   %
   %  fullpath = docpath(docname) returns the full path to the html document
   %  toolbox/docs/html/<docname>.html. If an m2html folder exists in the html/
   %  directory, then this function will search for a function documention file
   %  in toolbox/docs/html/m2html/<packagename>/<docname>.html
   % 
   % See also: buildpath
   
   docspath = fullfile(toolboxpath(), 'docs', 'html');
   [~, pkgfolder] = mpackagename();
   
   if isfile(fullfile(docspath, [docname '.html']))
      % help pages documentation
      fullpath = fullfile(docspath, [docname '.html']);
      
   elseif isfile(fullfile(docspath, 'm2html', pkgfolder, [docname '.html']))
      % function documentation      
      fullpath = fullfile(docspath, 'm2html', pkgfolder, [docname '.html']);
   end
end
