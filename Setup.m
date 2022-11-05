function Setup()
% Setup.m install the toolbox, set paths etc.

% turn off complaints about paths not already being on the path
warning off

% add paths containing source code
addpath(genpath([pwd() filesep '+bfra']));
addpath(genpath([pwd() filesep 'util']));

% remove git paths
rmpath(genpath([pwd() filesep '.git*']));

% remove paths containing example code
% rmpath(genpath([pwd() filesep 'examples']));

warning on 

% display install message
fprintf('\n * baseflow recession analysis activated *\n\n')
