function [funclist,prodlist] = dependencies(funcname,option)
% DEPENDENCIES generate a list of function and product dependencies for function
% 
%  Input
%     funcname = char of any function name
% 
%  Output
%     funclist = table with column of all functions that input funcname depends
%     on, the functions that each of those depends on, and the products that
%     each of those depends on
% 

% use this to generate a list of all functions in the package, then cycle over
% all of them and find the dependencies
% funcpath = fileparts(which('bfra.fitab'));
% funclist = getlist(funcpath,'.m');

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% valid options
validopts = ["all","missing","installed"];
for n = 1:numel(validopts)
   opts.(validopts(n)) = option == validopts(n);
end

% use this to test a particular function
% if nargin == 0
   % funcname = 'bfra_demo.mlx';
   % funcname = 'bfra_gettingStarted.m';
   % funcname = 'bfra.fitab';
   % funcname = 'bfra_kuparuk.m';
% end

funcpath = fileparts(which(funcname));
[funclist,prodlist] = matlab.codetools.requiredFilesAndProducts(funcname);
funclist = transpose(funclist);
prodlist = transpose(prodlist);

if opts.all == true
   % return a table of all dependencies
   funclist = cell2table(funclist,'VariableNames',{'function_dependencies'});
elseif opts.missing == true
   funclist = getmissingdependencies(funclist,funcname);
elseif opts.installed == true
   funclist = getinstalleddependencies(funclist);
end


function funclist = getmissingdependencies(funclist,funcname)

% remove functions in the toolbox first, leave the ones in util/ so they can be
% compared here if needed for debugging. 

% Also remove the 'cupid' toolbox and 'ExtractNameVal' functions that get
% picked up as dependent but are not. What remains after this is functions that
% are either in util/ or need to be moved there.
skip = {'+bfra',funcname,'ExtractNameVal','Cupid'};
keep = true(numel(funclist),1);
for n = 1:numel(funclist)
   keep(n) = ~contains(funclist{n},skip);
end
funclist = funclist(keep);

% now remove ones that are already in util. what remains are missing.
skip = {'bfra/util'};
keep = true(numel(funclist),1);
for n = 1:numel(funclist)
   keep(n) = ~contains(funclist{n},skip);
end
funclist = funclist(keep);

if isempty(funclist)
   funclist = 'all dependencies are installed';
else
   funclist = cell2table(funclist,'VariableNames',{'function_dependencies'});
end

%% internal use 
 
% cycle through the dependent functions and copy them to util/

% NOTE: this is for private use, it won't work if you don't have the functions
% on your local computer. Please contact me at matt.cooper@pnnl.gov if you have
% any trouble running this toolbox or if any function dependencies are missing
% from the toolbox. Alternatively, look for the missing functions in
% https://github.com/mgcooper/matfunclib (I suggest the dev branch). Thank you. 

% TODO: add method to clone from https://github.com/mgcooper/matfunclib

% for n = 1:numel(functionDependencies)
%    [~,fname,ext] = fileparts(functionDependencies{n});
%    copyfile(functionDependencies{n},['util/',fname,ext]);
% end

% any functions listed in dependentFunctions may be required for some fringe
% behavior in the toolbox but the core functionality should 

%%
% if the commented loop in bfra.util.dependencies.m is used, this is required 
% dependentFunctions = unique(vertcat(allDependencies.function_dependencies{:}));

% % nearly certain it isn't necessary to cycle over all functions, I may have
% added this to figure out which functions were responsible for some functions
% that were returned as required but sholdn't be like the Cupid toolbox

% Depends = cell(numel(funclist),3);
% for n = 1:numel(funclist)
%    
%    % this is needed if getlist is used
%    % thisfunc = [funcpath filesep funclist(n).name];
%    
%    thisfunc = funclist{n};
%    [fl,pl] = matlab.codetools.requiredFilesAndProducts(thisfunc);
%    fl = transpose(fl);
%    
%    Depends{n,1} = thisfunc;
%    Depends{n,2} = fl;
%    Depends{n,3} = {pl(:).Name}';
%   
% end
% 
% Depends = cell2table(Depends,'VariableNames',...
%    {'function_name','function_dependencies','product_dependencies'});











