function varargout = listfiles(foldername, opts)
   %LISTFILES List all files in folder and (optionally) subfolders.
   %
   % LIST = listfiles(FOLDERNAME) returns a directory structure in the same
   % format as DIR containing all files in directory FOLDERNAME
   %
   % LIST = listfiles(FOLDERNAME, 'aspathlist', true) returns fullpaths to
   % each file in a cell array rather than the default directory struct.
   %
   % LIST = listfiles(FOLDERNAME, 'aspathlist', true, 'asstring', true)
   % returns a string array rather than cell array.
   %
   % LIST = listfiles(_, 'mfiles', true) only returns .m files.
   %
   % LIST = listfiles(_, 'subfolders', true) returns all files in subfolders.
   %
   % Copyright (c) 2023, Matt Cooper, BSD 3-Clause License, github.com/mgcooper.
   %
   % See also: mfilename, mcallername, mfoldername, ismfile

   arguments
      foldername (1,:) string = pwd()
      opts.subfolders (1,1) logical = false;
      opts.asstruct (1,1) logical = true
      opts.aslist (1,1) logical = false
      opts.asstring (1,1) logical = false
      opts.fullpath (1,1) logical = false
      opts.mfiles (1,1) logical = false
   end

   % get all package folders
   if opts.subfolders == true
      list = dir(fullfile(foldername, '**/*'));
   else
      list = dir(fullfile(foldername));
   end
   list(strncmp({list.name}, '.', 1)) = [];
   list = list(~[list.isdir]);

   if opts.mfiles == true
      list = list(strncmp(reverse({list.name}), 'm.', 2));
   end

   if opts.aslist == true

      if opts.fullpath
         list = transpose(fullfile({list.folder},{list.name}));
      else
         list = transpose(fullfile({list.name}));
      end

      % convert to string array if requested
      if opts.asstring == true
         list = string(list);
      end
   end

   varargout{1} = list;
end
