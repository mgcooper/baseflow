function [pkgname, withplus] = mpackagename()
   %MPACKAGENAME Return the package namespace name.
   %
   %  [PKGNAME, WITHPLUS] = MPACKAGENAME() Returns the package name and the
   %  package name preceded by a plus sign, both as a char.
   %
   % See also: mpackagefolders
   
   pkgname = fileparts(fileparts(fileparts(mfilename("fullpath"))));
   [~, withplus] = fileparts(pkgname);
   pkgname = strrep(withplus, '+', '');
end