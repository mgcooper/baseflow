clean

% this script should resolve any errors due to missing function dependencies.
% all required functions should be included in the toolbox, but this can be used
% to check in case any errors come up. It also returns a list of the required
% products. The list will include the symbolic math toolbox and signal
% processing toolbox, but they are not actually required, its a bug in the
% built-in function. 

%% get all unique dependencies
funcname = 'demo_bfra.mlx';
[functionDependencies,productDependencies] = bfra.dependencies(funcname);
functionDependencies = table2cell(unique(functionDependencies));

%% remove functions in the toolbox

% also remove the 'cupid' toolbox and the 'ExtractNameVal' functions which get
% picked up as dependent but are not.
skip = {'Cupid','+bfra','bfra/util','ExtractNameVal','magicParser','setpath',funcname};
keep = true(numel(functionDependencies),1);
for n = 1:numel(functionDependencies)
   keep(n) = ~contains(functionDependencies{n},skip);
end
functionDependencies = functionDependencies(keep);

%% cycle through the dependent functions and copy them to util/

% NOTE: this is for private use, it won't work if you don't have the functions
% on your local computer. Please contact me at matt.cooper@pnnl.gov if you have
% any trouble running this toolbox or if any function dependencies are missing
% from the toolbox. Alternatively, look for the missing functions in
% https://github.com/mgcooper/matfunclib (I suggest the dev branch). Thank you. 

% TODO: add method to clone from https://github.com/mgcooper/matfunclib

for n = 1:numel(functionDependencies)
   [~,fname,ext] = fileparts(functionDependencies{n});
   copyfile(functionDependencies{n},['util/',fname,ext]);
end

% any functions listed in dependentFunctions may be required for some fringe
% behavior in the toolbox but the core functionality should 


%%
% if the commented-out loop in Dependencies.m is used, this is required
% dependentFunctions = unique(vertcat(allDependencies.function_dependencies{:}));