function makecontents(varargin)
   %MAKECONTENTS Make contents.m for each toolbox folder including packages.
   %
   %  makecontents() Makes a Contents.m file for each folder in the
   %  projectpath/toolbox directory. This usage assumes this file is saved in:
   %  projectpath/toolbox/+tbx/+internal.
   %
   %  makecontents('-backup') Makes a backup of the current Contents.m file, if
   %  one exists, before updating it. The backup file is saved in the same
   %  directory with the date appended to the filename.
   % 
   % See also: updatecontents

   narginchk(0, 1)
   
   % Get the toolbox path and set the backup option
   tbxpath = toolboxpath(); % call private/toolboxpath function
   if nargin == 1
      option = validatestring(varargin{1}, {'-backup', '-nobackup'});
   else
      option = '-backup';
   end
   dobackup = strcmp(option, '-backup');

   if ~isfolder(tbxpath)
      error('toolbox folder not found')
   end
   
   % toolbox contents
   % tbxlist = what(tbxpath);

   % package and subpackage folders
   pkglist = mpackagefolders(tbxpath, "aspathlist", true, "asstring", true);

   % traverse package folders and generate a contents report in each one
   for thispkg = pkglist(:).'
      processOnePackage(thispkg, dobackup);
   end
end

%% subfunction to handle each package folder individually
function processOnePackage(thispkg, dobackup)

   % With "mfiles", true, this will return an empty list for docs/html folders.
   filelist = listfiles(thispkg, "aslist", true, ...
      "fullpath", true, "asstring", true, "mfiles", true);

   if isempty(filelist)
      return
   end

   % If there is no existing Contents file, try to make one
   if ~any(strncmp(reverse(filelist), reverse('Contents.m'), 10))
      try
         makecontentsfile(char(thispkg))
      catch
      end
   end

   % If an existing Contents file is found, update it.
   if any(strncmp(reverse(filelist), reverse('Contents.m'), 10))
      % Copy the current Contents to a temp file so it is not included as an
      % entry in the new Contents.m file.
      [bkfile, ogfile, tmpfile] = backupContentsFile(filelist);

      % Try to update the Contents file.
      success = true;
      try
         cdobj = withcd(thispkg); %#ok<NASGU>
         updatecontents();
      catch
         success = false;
         fprintf(2, ...
            ['Error occurred while generating contents for package %s. ' ...
            'Restoring the original Contents.m\n'], thispkg);
      end

      % If successful, copy the tmpfile to the backupfile.
      if success == true
         if dobackup
            cleanupfun(tmpfile, bkfile)
         end
      else
         % If not successful, restore the original file.
         cleanupfun(tmpfile, ogfile)
      end
   else
      % No file found
   end
end
%% local functions
function [bkfile, ogfile, tmpfile] = backupContentsFile(filelist)
   % Move the existing Contents.m file to a tempfile and create a backup
   % filename. If -backup option is passed to the main function, the original
   % file is copied to the backup file name after successful generation of the
   % new Contents.m file. If the generation is not successful, the tempfile is
   % copied back to the original Contents.m file.
   ifile = strncmp(reverse(filelist), reverse('Contents.m'), 10);
   tmpfile = tempfile('fullpath');
   bkfile = backupfile('Contents.m');
   ogfile = filelist(ifile);
   bkfile = fullfile(fileparts(ogfile), bkfile);
   movefile(ogfile, tmpfile)
end

function cleanupfun(tmpfile, destinationfile)
   movefile(tmpfile, destinationfile);
end
