function fullpath = buildpath(varargin)
   %BUILDPATH Build full path to toolbox folder or file.
   %
   % FULLPATH = BUILDPATH() Returns the full path to the toolbox/ folder.
   % FULLPATH = BUILDPATH(FOLDERNAME)
   % FULLPATH = BUILDPATH(FOLDERNAME, FILENAME)
   %
   % Description
   % FULLPATH = BUILDPATH() Returns the full path to the toolbox/ folder.
   %
   % FULLPATH = BUILDPATH(FOLDERNAME) Returns the full path to the
   % toolbox/FOLDERNAME folder. 
   %
   % FULLPATH = BUILDPATH(FOLDERNAME, FILENAME) Returns the full path to the
   % toolbox/FOLDERNAME/FILENAME file.
   %
   % FULLPATH = BUILDPATH(varargin) Recursively appends the contents of varargin
   % to the toolbox/ folder.
   %
   % See also: 

   % Ensure inputs are chars
   args = parseinputs(varargin{:});
   fullpath = toolboxpath();

   % Recursively validate sub-folders and append them to the path string.
   for subpath = args(:)'
      validatestring(subpath{:}, listfolders(fullpath), mfilename, 'SUBFOLDER');
      fullpath = fullfile(fullpath, subpath{:});
   end
end

% Convert strings to chars
function args = parseinputs(varargin)
   args = varargin;
   if isoctave
      for n = 1:numel(args)
         try
            args{n} = char(args{n});
         catch ME
         end
      end
   else
      [args{:}] = convertStringsToChars(args{:});
   end
   cellfun(@(arg) validateattributes(arg, {'char'}, {'row'}), args)
end
