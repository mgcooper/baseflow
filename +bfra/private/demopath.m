function fullpath = demopath(varargin)
   fullpath = fullfile(basepath(), 'demos', varargin{:});
end