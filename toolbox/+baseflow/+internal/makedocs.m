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
   %
   % See also: 

   % Retrieve the package namespace folder
   [~, pkgfolder] = mpackagename();
   
   % Parse optional arguments
   validopts = {'docpages', 'demos', 'functions', 'docsearch'};
   narginchk(0, numel(validopts))

   % If no input, build all docs
   if nargin == 0
      varargin = validopts;
   end

   % Convert to a struct array of logical flags
   opts = cell2struct(num2cell(cellfun(@(arg) ismember(arg, varargin), ...
      validopts)), validopts, 2);

   % Set paths to the toolbox folder, docs, demos, and html folders
   demopath = fullfile(toolboxpath(), 'demos');
   docspath = fullfile(toolboxpath(), 'docs');
   htmlpath = fullfile(toolboxpath(), 'docs', 'html');
   indexpath = fullfile(projectpath(), 'docs');

   % Nest m2html/ in html/ to distinguish it from stuff published using matlab
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
      convertlivescripts();
   end

   %% build a doc search database

   if opts.docsearch == true
      builddocsearchdb(htmlpath)
   end

   %% publish the example documentation using publish

   if opts.docpages == true

      % publish the standard docs using matlab's publish
      publish(fullfile(docspath, 'baseflow_welcome.m'), mpubopts);
      publish(fullfile(docspath, 'baseflow_gettingStarted.m'), mpubopts);
      publish(fullfile(docspath, 'baseflow_contents.m'), mpubopts);
      publish(fullfile(docspath, 'baseflow_theory_contents.m'), mpubopts);
      publish(fullfile(docspath, 'baseflow_examples_contents.m'), mpubopts);

      % for github actions the landing page must be saved as docs/index.html
      % where docs/ is at the top-level.
      copyfile( ...
         fullfile(htmlpath, 'baseflow_gettingStarted.html'), ...
         fullfile(indexpath, 'index.html'));
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
      job = withcd(toolboxpath()); %#ok<NASGU>

      % note that m2html uses relative paths. generate a list of dirs to ignore.
      alldirs = dir(pwd());
      alldirs = alldirs([alldirs.isdir]);
      alldirs(strncmp({alldirs.name}, '.', 1) & strlength({alldirs.name})<3) = [];
      ignored = {alldirs(~ismember({alldirs.name}, pkgfolder)).name};

      % folder containing code to generate documentation
      mfilepath = fullfile(pkgfolder);

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
         'template', 'blue2_baseflow', ...        % other template
         'ignored', ignored, ...              % dirs to ignore
         'verbose', 'on' ...
         );
   end
end
