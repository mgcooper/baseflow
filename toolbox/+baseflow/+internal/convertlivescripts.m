function convertlivescripts(varargin)
   %CONVERTLIVESCRIPTS convert live script to m-files.
   %
   %  convertlivescripts() Converts the .mlx live scripts in demos/ to mfiles
   %  in demos/mfiles. The mfiles can run in Octave, the .mlx files cannot. The
   %  existing mfiles are backed up to a folder and zipped.
   %
   %  convertlivescripts('-nobackup') Does not create the backup zip folder.
   %
   % See also: makedocs

   % Note: the demos and the live scripts are not exactly the same b/c the demos
   % are octave compatible, so dont run this without first checking the
   % differences and then fixing them. The main thing is probably how the data
   % is loaded.

   if nargin < 1
      opt = '-backup';
   else
      opt = validatestring(varargin{1}, {'-nobackup', '-backup'}, ...
         mfilename, 'OPT', 1);
   end

   demopath = baseflow.internal.demopath();
   mfilepath = fullfile(demopath, 'mfiles');
   livescripts = dir(fullfile(demopath, '*.mlx'));

   % Backup the existing files
   if strcmp(opt, '-backup')
      mfiles = dir(fullfile(mfilepath, '*.m'));
      if numel({mfiles.name}) > 0
         backupfile(mfilepath, true, true);
      end
   else
      % do nothing
   end

   for n = 1:numel(livescripts)
      infile = fullfile(demopath, livescripts(n).name);
      outfile = fullfile(mfilepath, strrep(livescripts(n).name, '.mlx', '.m'));
      export(infile, outfile);
   end
end
