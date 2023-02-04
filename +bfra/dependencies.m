function [funclist,prodlist] = dependencies(funcname)
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

% use this to test a particular function
if nargin == 0
   funcname = 'bfra_demo.mlx';
   % funcname = 'bfra_gettingStarted.m';
   % funcname = 'bfra.fitab';
   % funcname = 'bfra_kuparuk.m';
end

funcpath = fileparts(which(funcname));
[funclist,prodlist] = matlab.codetools.requiredFilesAndProducts(funcname);
funclist = transpose(funclist);
prodlist = transpose(prodlist);

funclist = cell2table(funclist,'VariableNames',{'function_dependencies'});

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











