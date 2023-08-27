function convertlivescripts

   % Note: the demos and the live scripts are not exactly the same b/c the demos
   % are octave compatible, so dont run this without first checking the
   % differences and then fixing them. The main thing is probably how the data
   % is loaded. 

   demopath = bfra.util.basepath('demos');
   livescripts = dir(fullfile(demopath,'*.mlx'));

   for n = 1:numel(livescripts)
      infile = fullfile(livescripts(n).folder,livescripts(n).name);
      outfile = strrep(infile,'.mlx','.m');
      export(infile,outfile);
   end
end