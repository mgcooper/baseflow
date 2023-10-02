function varargout = mpackagefolders(foldername, opts)
   %MPACKAGEFOLDERS List all package and sub-package folders in folder
   %
   % LIST = mpackagefolders(FOLDERNAME) returns a directory structure in the
   % same format as DIR containing all package folders and subpackage folders
   % relative to top-level directory FOLDERNAME
   %
   % LIST = mpackagefolders(FOLDERNAME, 'aspathlist', true) returns fullpaths to
   % each package in a cell array rather than the default directory struct.
   %
   % LIST = mpackagefolders(FOLDERNAME, 'aspathlist', true, 'asstring', true)
   % returns a string array rather than cell array.
   %
   % Copyright (c) 2023, Matt Cooper, BSD 3-Clause License, github.com/mgcooper
   %
   % See also: mpackagename, mfilename, mcallername, mfoldername, ismfile

   arguments
      foldername (1,:) string = pwd()
      opts.asstruct (1,1) logical = true
      opts.aspathlist (1,1) logical = false
      opts.asstring (1,1) logical = false
   end

   % list all items in top-level folder
   toplist = what(foldername);
   numpkgs = numel(toplist.packages);

   if numpkgs == 0
      fprintf('no packages found in %s\n', foldername)
      varargout{1} = [];
      return
   else

      % get all package folders
      pkglist = dir(fullfile(foldername, '**/*'));
      pkglist(strncmp({pkglist.name}, '.', 1)) = [];
      pkglist = pkglist([pkglist.isdir]);
      pkglist = pkglist(strncmp({pkglist.name}, '+', 1));
   end

   if opts.aspathlist == true
      pkglist = transpose(fullfile({pkglist.folder},{pkglist.name}));

      % convert to string array if requested
      if opts.asstring == true
         pkglist = string(pkglist);
      end
   end

   varargout{1} = pkglist;
end
