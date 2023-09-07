function fullpath = demopath(varargin)
   %DEMOPATH Return toolbox demo path.
   fullpath = fullfile(basepath(), 'demos', varargin{:});
end