function tbpath = installpath(tbxname)
   %INSTALLPATH Return toolbox installation path.
   if nargin < 1
      tbxname = mpackagename();
   end
   tbpath = getpref(tbxname,'install_directory');
end
