function convertlivescripts

demopath = bfra.util.basepath('demos');
livescripts = dir(fullfile(demopath,'*.mlx'));

for n = 1:numel(livescripts)
   infile = fullfile(livescripts(n).folder,livescripts(n).name);
   outfile = strrep(infile,'.mlx','.m');
   export(infile,outfile);
end