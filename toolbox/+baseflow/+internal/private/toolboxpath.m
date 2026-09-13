function fullpath = toolboxpath()
   %TOOLBOXPATH Return toolbox basepath.
   %
   %  fullpath = toolboxpath() returns the folder four levels above this
   %  file, which is the toolbox folder that contains the +baseflow
   %  package.
   fullpath = fileparts(fileparts(fileparts(fileparts( ...
      mfilename('fullpath')))));
end
