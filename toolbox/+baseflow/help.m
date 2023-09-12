function help(docname)
   %HELP Open toolbox html help document in the MATLAB Help browser.
   %
   % baseflow.help() opens the baseflow toolbox help pages in the MATLAB help
   % browser.
   %
   % baseflow.help(DOCNAME) opens the documentation file DOCNAME.HTML in the matlab
   % help browser. DOCNAME can be the name of a function, an example/demo, or
   % any other file with an .html extension in the docs/ folder or any subfolder
   % of docs/.
   %
   % % Example: Open the function documentation for baseflow.getevents.
   %
   % baseflow.help('getevents')
   %
   % See also: privatefunction, completions, showdemo

   if usejava('desktop')
      % might need this, if web does not do the appropriate error checking.
      % also see 'demo', 'showdemo', and 'open'
   end

   % docname should point to an html help file
   if nargin < 1
      docname = 'baseflow_welcome';
   end
   
   % Not sure if there is any benefit to 'web' vs 'showdemo' vs 'demo'
   web(baseflow.internal.docpath(docname)) 
end