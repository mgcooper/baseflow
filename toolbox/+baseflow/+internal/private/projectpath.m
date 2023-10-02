function fullpath = projectpath()
   %PROJECTPATH Return the full path to the top-level project directory.
   %
   %  fullpath = projectpath() Returns the full path to the directory located
   %  five levels above this one: project/toolbox/+pkg/+internal/private
   %                                ↑↑↑                            ↑↑↑
   %                           project folder                  this folder
   %
   % See also: toolboxpath, buildpath

   fullpath = fileparts(fileparts(fileparts(fileparts(fileparts( ...
      mfilename('fullpath'))))));
end
