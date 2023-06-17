function projpath = basepath(varargin)

projpath = fileparts(fileparts(fileparts(mfilename('fullpath'))));

if nargin == 1
   projpath = fullfile(projpath, varargin{:});
end

