function tbpath = installpath(tbxname)
   %INSTALLPATH Return toolbox installation path.
   %
   %  tbpath = installpath(tbxname) returns the 'install_directory'
   %  preference (getpref) for the toolbox named tbxname. tbxname defaults
   %  to the package name from mpackagename().
   if nargin < 1
      tbxname = mpackagename();
   end
   tbpath = getpref(tbxname,'install_directory');
end
