function makedocs(varargin)
   %MAKEDOCS publish GettingStarted.m as index.html for GitPages.
   %
   % Note: the repo is configured to publish from docs/ and the default action
   % publishes index.html using jekyll. For custom builds, use a .nojekyll file
   %
   % Publish options:
   % docs pages
   % demos
   % function docs
   % re-build docsearch database

   % Parse optional arguments
   validopts = {'docpages', 'demos', 'functions', 'docsearch', 'testrun'};
   narginchk(0, numel(validopts))

   % If no input, build all docs
   if nargin == 0
      varargin = validopts(1:4);
   end

   % Convert to a struct array of logical flags
   opts = cell2struct(num2cell(cellfun(@(arg) ismember(arg, varargin), ...
      validopts)), validopts, 2);

   % Set paths to this folder and the toolbox base path
   thispath = fileparts(mfilename('fullpath'));
   basepath = fileparts(thispath);

   % Test run option publishes to an ignored testbed/ folder
   if opts.testrun == true
      docspath = fullfile(basepath, 'testbed', 'docs');
      if ~isfolder(docspath)
         error('testbed/docs folder does not exist')
      end
   else
      docspath = thispath;
   end

   % Path to live script demos
   demopath = fullfile(basepath, 'demos');

   % Path to save the html files. Nest m2html/ in html/ to distinguish it from
   % matlab publish stuff
   htmlpath = fullfile(docspath, 'html');
   m2htmlpath = fullfile(htmlpath, 'm2html');

   % matlab publish opts
   mpubopts = struct( ...
      'format', 'html', ...
      'outputDir', htmlpath, ...
      'useNewFigure', false ...
      );

   % Do some checks before proceeding
   assert(isfolder(docspath), 'docs folder is missing')
   assert(isfolder(demopath), 'demo folder is missing')
   assert(isfolder(htmlpath), 'html folder is missing')
   assert(isfolder(m2htmlpath), 'm2html folder is missing')

   %% publish live scripts as demo html files and octave-compatible mfiles

   if opts.demos
      filelist = dir(fullfile(demopath, '*.mlx'));

      for n = 1:numel(filelist)
         demofile = fullfile(filelist(n).folder, filelist(n).name);
         [~, filename] = fileparts(demofile);
         htmlfile = fullfile(htmlpath, [filename '.html']);

         export(demofile, htmlfile);
      end

      % To convert to m-files, use convertlivescripts
      convertlivescripts
   end

   %% build a doc search database

   if opts.docsearch == true
      builddocsearchdb(htmlpath)
   end

   %% publish the example documentation using publish

   if opts.docpages == true

      % publish the standard docs using matlab's publish
      publish(fullfile(docspath, 'bfra_welcome.m'), mpubopts);
      publish(fullfile(docspath, 'bfra_gettingStarted.m'), mpubopts);
      % publish(fullfile(docspath, 'bfra_contents.m'), mpubopts);
      publish(fullfile(docspath, 'bfra_theory_contents.m'), mpubopts);
      publish(fullfile(docspath, 'bfra_examples_contents.m'), mpubopts);

      % for github actions the landing page must be saved as docs/index.html
      % where docs/ is at the top-level.
      copyfile(fullfile(htmlpath, 'bfra_gettingStarted.html'), ...
         fullfile(fileparts(basepath), 'docs', 'index.html'));

      % not sure if other files can also be supported, if so:
      % copyfile('html/bfra_demo.html','bfra_demo.html');
   end

   %% publish the function documentation using m2html

   if opts.functions == true

      % activate m2html
      try
         activate m2html_rochefort
      catch e
         rethrow(e)
      end

      % run m2html from the project base directory (one dir above this one)
      job = withcd(basepath); %#ok<NASGU>

      % note that m2html uses relative paths. generate a list of dirs to ignore.
      alldirs = dir([basepath filesep]); alldirs = alldirs([alldirs.isdir]);
      alldirs(strncmp({alldirs.name}, '.', 1) & strlength({alldirs.name})<3) = [];
      ignored = {alldirs(~ismember({alldirs.name},'+bfra')).name};

      % folder containing code to generate documentation
      mfilepath = fullfile('+bfra');

      if ~isfolder(m2htmlpath)
         mkdir(m2htmlpath)
      end

      m2html( ...
         'mfiles', mfilepath, ...             % source dir where the files live
         'htmldir', m2htmlpath, ...           % dest dir where the html files go
         'recursive', 'off', ...              % recurse through the source dir
         'source', 'on', ...                  % include source code or not
         'download', 'off', ...               % include link to download each file
         'syntaxHighlighting', 'on', ...      % source code syntax hightlight
         'globalHypertextLinks', 'off', ...   % hyperlinks among other matlab folders
         'graph', 'on', ...                   % graphviz dependency graph
         'indexFile', 'function_index', ...   % basename of the HTML index file
         'template', 'blue2_bfra', ...        % other template
         'ignored', ignored, ...              % dirs to ignore
         'verbose', 'on' ...
         );
   end


   %%% notes

   % % this is how m2html installs its own docs:
   % m2html( ...
   %    'mfiles','m2html', ...
   %    'htmldir','doc', ...
   %    'recursive','on', ...
   %    'global','on', ...
   %    'graph','on' ...
   %    );

   %%% placing makedocs in the docs/ folder
   %
   % I was going to try to replace all occurrences of '../+bfra' with
   % 'm2html/+bfra' to avoid having makedocs in the top-level directory because
   % m2html accepts relative paths only, but it's too complicated so just make
   % everything relative to the top
   %
   % xmlread('m2html/function_index.html')
   %
   % fid = fopen('m2html/function_index.html','w');
   % wholefile = fscanf(fid,'%c');
   % fclose(fid);
   %
   % replace all occurrences of '../+bfra' with 'm2html/+bfra'

   %%% template notes
   %
   % in the template folders, master.tpl controls the landing page, mdir.tpl
   % controls the page when you click on a folder from the landing page, mfile.tpl
   % controls the page for the mfiles,

   %%% resources

   % m2docgen looks promising - it calls builddocsearchdb

   % http://comisef.wikidot.com/tutorial:ml-tt1
   % https://www.mathworks.com/matlabcentral/answers/58438-which-tool-are-you-using-to-create-the-documentation-of-your-matlab-codes
   % https://www.mathworks.com/matlabcentral/fileexchange/96289-m2docgen?s_tid=FX_rc1_behav
   % https://www.mathworks.com/matlabcentral/fileexchange/9032-makehtmldoc
   % https://www.mathworks.com/matlabcentral/fileexchange/25925-using-doxygen-with-matlab
   % https://pypi.org/project/sphinxcontrib-matlabdomain/

end