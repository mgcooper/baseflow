function [fullpath_bk, filename_bk] = backupfile(filename, makecopy, makezip)
   %BACKUPFILE Create a backup file name or folder name and (optionally) a copy.
   %
   % [fullpath_bk, filename_bk] = backupfile(filename) returns the name and
   % full path of the backup file or folder without actually making a copy.
   %
   % [fullpath_bk, filename_bk] = backupfile(filename, true) makes a copy.
   %
   % [fullpath_bk, filename_bk] = backupfile(filename, true, true) makes a copy
   % and moves the copy to a zip file.
   %
   % Note: Provide the full path to avoid unexpected behavior especially when
   % working with private directories or paths not in the MATLAB search space.
   %
   % Examples:
   % 1. backupfile('/Users/user/test.m')
   % 2. backupfile('/Users/user/test_folder', true)
   %
   % See also: tempdir, tempfile

   if nargin < 2
      makecopy = false;
   end
   if nargin < 3
      makezip = false;
   end
   filename = convertStringsToChars(filename);
   validateattributes(filename, {'char'}, {'row'}, mfilename, 'FILENAME', 1)
   validateattributes(makecopy, {'logical'}, {'scalar'}, mfilename, 'MAKECOPY', 2)
   validateattributes(makezip, {'logical'}, {'scalar'}, mfilename, 'MAKEZIP', 3)

   % Generate a date-time string to append to the file name.
   filedate = mkfiledate('dd-MMM-yyyy_hh-mm-ss');

   % Remove trailing filesep if it exists.
   filename = rmtrailingsep(filename);

   % Get the parent folder path, filename, and file extension.
   [filepath, filename, fileext] = fileparts(filename);
   fullpath = fullfile(filepath, [filename fileext]);

   % Create a back up file (or folder) name and full path.
   filename_bk = [filename '_' filedate fileext];
   fullpath_bk = fullfile(filepath, filename_bk);

   if makecopy
      if isfile(fullpath_bk) || isfolder(fullpath_bk)
         warning('Backup already exists. No copy made.');
      else
         try
            copyfile(fullpath, fullpath_bk);
         catch e
            rethrow(e)
         end

         if makezip
            zip(fullpath_bk, fullpath_bk);
            if isfolder(fullpath_bk)
               rmdir(fullpath_bk, "s");
            elseif isfile(fullpath_bk)
               delete(fullpath_bk);
            end
            filename_bk = [filename_bk '.zip'];
            fullpath_bk = [fullpath_bk '.zip'];
         end
         fprintf('Backup created: %s\n', fullpath_bk);
      end
   end
end

function filedate = mkfiledate(dateformat)
   if nargin < 1
      dateformat = 'dd-MMM-yyyy_HH-mm-ss';
   end
   filedate = strrep(char(datetime('now', 'Format', dateformat)), '-', '');
end

function filename = rmtrailingsep(filename)
   if strcmp(filename(end), filesep)
      filename(end) = [];
   end
end

% Unused material

% % If the backup file exists, recursively append versions starting with _v2
%    % until the version number does not exist.
%    if isfile(filename_bk) || isfolder(filename_bk)
%       n = 2;
%       while isfile(filename_bk) || isfolder(filename_bk)
%          filename_bk = [filename '_bk_' filedate '_v' num2str(n) fileext];
%          n = n+1;
%       end
%    end

% This would go after the n = n+1 end to copy the existing backup file to _v0.
% To use this, add back % fullpath_bk = [filepath filename_bk];

% This assumes _v0 does not exist, so I commented it out instead of
% checking, just leave it if it exists and create new ones with _vX.
% movefile(fullpath_bk, strrep(fullpath_bk, fileext, ['_v0' fileext]));