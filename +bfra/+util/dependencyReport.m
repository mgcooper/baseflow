function deps = dependencyReport(varargin)

func = fullfile(bfra.util.getinstallationpath,'docs','bfra_demo.m');
report = bfra.util.dependencies(func,'report');
deps = report.function_dependencies; % if i decide to return as table
deps = cellfun(@(x)strrep(x,[fileparts(x) filesep],''),deps,'uni',0);
deps = sort(string(deps));
fname = fullfile(bfra.util.getinstallationpath,'+bfra','+util','dependencies.mat');
report.function_dependencies = deps;
save(fname,'report');

% % to save as a textfile in the top-level
% fname = fullfile(bfra.util.getinstallationpath,'dependencies.txt');
% fid = fopen(fname,'w');
% n = 0;
% while n<numel(deps)
%    n = n+1;
%    fprintf(fid,'%s\n',deps{n});
% end
% fclose(fid);