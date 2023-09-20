function replacePackagePrefix(projectpath, old_pfx, new_pfx, dryrun)
   %REPLACEPACKAGEPREFIX Replace namespace package prefix in function files.
   %
   % replacePackagePrefix(projectpath, old_pfx, new_pfx, true) Replaces all
   % instances of OLD_PFX with NEW_PFX in all m-files in PROJECTPATH and all
   % subdirectories. 
   % 
   % replacePackagePrefix(projectpath, old_pfx, new_pfx, false) Performs a dry
   % run. 
   % 
   % See also: 

   narginchk(3, 4)
   if nargin < 4 || isempty(dryrun)
      dryrun = true;
   end

   if isoctave
      error([mfilename ' is not octave compatible'])
   end
   
   [projectpath, old_pfx, new_pfx] = convertStringsToChars( ...
      projectpath, old_pfx, new_pfx);
   
   % Confirm that the last character of the old/new prefix is a dot
   if ~endsWith(old_pfx, '.')
      old_pfx = [old_pfx '.'];
   end
   if ~endsWith(new_pfx, '.')
      new_pfx = [new_pfx '.'];
   end
   
   % cd to the package folder where the code is saved
   withcd(projectpath());

   % Generate a list of all mfiles in the project
   list = dir(fullfile('**/*.m'));
   list(strncmp({list.name}, '.', 1)) = [];
   list(contains({list.folder}, 'sandbox'))

   % OPEN ALL THE FILES AND REPLACE THE PREFIX

   for n = 1:numel(list)

      filename = fullfile(list(n).folder, list(n).name);
      fid = fopen(filename);

      % read in the function to a char
      wholefile = fscanf(fid, '%c'); fclose(fid);

      % replace the prefix
      if contains(wholefile, old_pfx)

         wholefile = strrep(wholefile, old_pfx, new_pfx);

         % REWRITE THE FILE (DANGER ZONE)
         if dryrun == false
            fid = fopen(filename, 'wt');
            fprintf(fid, '%c', wholefile); fclose(fid);
         else
            disp(filename)
         end
      end
   end
end
