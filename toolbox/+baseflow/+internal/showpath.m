function [prjpath, tbxpath] = showpath()
   %SHOWPATH Show the output of projectpath() and toolboxpath() to verify.
   prjpath = projectpath();
   tbxpath = toolboxpath();
end