function fullpath = toolboxpath()
   %TOOLBOXPATH Return toolbox basepath.
   fullpath = fileparts(fileparts(fileparts(fileparts( ...
      mfilename('fullpath')))));
end
