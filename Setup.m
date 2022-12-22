function Setup()
% SETUP install the toolbox, set paths etc.

% temporarily turn off warnings about paths not already being on the path
warning off

% Get the path to this file, in case Setup is run from some other folder. More
% robust than pwd(), but assumes the directory structure has not been modified.
thisfile = mfilename('fullpath');
thispath = fileparts(thisfile);

% add paths containing source code
% addpath(genpath([thispath filesep '+bfra']));
% addpath(genpath([thispath filesep 'util']));

% for octave compat, add all paths then remove +bfra
addpath(genpath(thispath));
rmpath(genpath([thispath filesep '+bfra']));

% remove git paths
rmpath(genpath([thispath filesep '.git*']));

% remove paths containing example code
% rmpath(genpath([thispath filesep 'examples']));

% save the path??
% savepath;
% for now - let the user decide

% warning on

% display install message
fprintf('\n * baseflow recession analysis activated *\n\n');


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%  not implemented

% Store the default options as prefs on this machine.
% The user can change these with bfra.setopts.

% This would store the opts in 'opts' which could be saved as a .mat file.
% opts = bfra.setopts;

% % Alternatively, modify bfra.setopts to add the options as custom prefs:
% addpref('bfra','version','1.0.0');






