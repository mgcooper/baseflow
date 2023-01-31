function Setup(varargin)
% SETUP install the toolbox, set paths etc.

% temporarily turn off warnings about paths not already being on the path
warning off

%% add paths
% Get the path to this file, in case Setup is run from some other folder. More
% robust than pwd(), but assumes the directory structure has not been modified.
thispath = fileparts(mfilename('fullpath'));

% NOTE genpath ignores folders named private, folders that begin with the @
% character (class folders), folders that begin with the + character (package
% folders), folders named resources, or subfolders within any of these.

% add paths containing source code
addpath(genpath(thispath));

% remove namespace +bfra and git directories from path
rmpath(genpath(fullfile(thispath,'+bfra')));
rmpath(genpath(fullfile(thispath,'.git')));

% remove paths containing example code
% rmpath(genpath(fullfile(thispath,'examples')));

% save the path??
% savepath;
% for now - let the user decide

%% run Config, Startup, read .env, etc

% TODO

%% resolve dependencies

% TODO

%% final steps

% turn warning back on
warning on

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






