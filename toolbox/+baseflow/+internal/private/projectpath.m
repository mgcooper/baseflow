function fullpath = projectpath()
   %PROJECTPATH Return project basepath.
   fullpath = fileparts(fileparts(fileparts(fileparts(fileparts( ...
      mfilename('fullpath'))))));
end