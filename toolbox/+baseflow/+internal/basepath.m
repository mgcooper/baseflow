function projpath = basepath(varargin)
   %BASEPATH Return toolbox basepath.
   %
   % Deprecated by BUILDPATH, kept for backward compatibility.
   %
   % See also: buildpath
   projpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

   if nargin == 1
      projpath = fullfile(projpath, varargin{:});
   end
end
