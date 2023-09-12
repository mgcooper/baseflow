function fullpath = demopath(varargin)
   %DEMOPATH Return toolbox demo path.
   fullpath = fullfile(baseflow.internal.basepath(), 'demos', varargin{:});
end