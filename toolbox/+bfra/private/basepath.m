function projpath = basepath(varargin)
   %BASEPATH Return toolbox basepath.
   projpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

   if nargin == 1
      projpath = fullfile(projpath, varargin{:});
   end

end