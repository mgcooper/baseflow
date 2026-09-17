function makedocs(varargin)
   %MAKEDOCS publish GettingStarted.m as index.html for GitPages.
   %
   % Note: the repo is configured to publish from docs/ and the default action
   % publishes index.html using jekyll. For custom builds, use a .nojekyll file
   %
   % Publish options:
   % docs pages (also copies the Getting Started page and its equation
   %    images to docs/index.html and docs/)
   % demos
   % function docs (the 'functions' option uses the vendored m2html in
   %    tools/m2html and needs Graphviz dot)
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

         % The demos do not close figures. Snapshot the open figures before
         % the export, so the cleanup below deletes only the new figures.
         % Hide their handles during the export, so a demo that draws into
         % the current figure (gcf) cannot draw into a figure the user has
         % open.
         figsbefore = findall(groot, 'Type', 'figure');
         visibility = get(figsbefore, {'HandleVisibility'});
         set(figsbefore, 'HandleVisibility', 'off')

         % Register the cleanup before the export, so it also runs when a
         % demo errors. The cleanup deletes the figures the export opened,
         % so figures do not accumulate during the docs build, and restores
         % the handle visibility of the other figures.
         figcleanup = onCleanup(@() cleanupdemofigures( ...
            figsbefore, visibility));

         % Run each live script so the html shows outputs from the current
         % code, not the outputs saved in the mlx file.
         export(demofile, htmlfile, 'Run', true);

         % Run the cleanup before the next demo.
         clear figcleanup
      end

      % The Octave-compatible m-files in demos/mfiles are maintained by
      % hand, so this step does not overwrite them. To convert the live
      % scripts to m-files, run convertlivescripts and review the diff.
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
      publish(fullfile(docspath, 'baseflow_powerlaw_notation.m'), mpubopts);

      % for github actions the landing page must be saved as docs/index.html
      % where docs/ is at the top-level.
      copyfile( ...
         fullfile(htmlpath, 'baseflow_gettingStarted.html'), ...
         fullfile(indexpath, 'index.html'));

      % index.html links the equation images by file name. Copy them next
      % to index.html, or the landing page shows broken images. copyfile
      % errors when no file matches, so skip the copy for a page with no
      % equations.
      eqimages = fullfile(htmlpath, 'baseflow_gettingStarted_eq*.png');
      if ~isempty(dir(eqimages))
         copyfile(eqimages, indexpath);
      end
   end

   %% publish the function documentation using m2html

   if opts.functions == true

      % Put the vendored m2html first on the path for this build, so the
      % build does not depend on a local m2html install. m2html finds its
      % templates next to m2html.m, so tools/m2html keeps the upstream
      % layout. restorepath restores the original path when makedocs returns.
      m2htmltool = fullfile(projectpath(), 'tools', 'm2html');
      assert(isfile(fullfile(m2htmltool, 'm2html.m')), ...
         'baseflow:makedocs:missingM2html', ...
         'The vendored m2html is missing: %s', m2htmltool)
      origpath = path();
      restorepath = onCleanup(@() path(origpath));
      addpath(m2htmltool);

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

      % The dependency graph needs Graphviz dot (tools/m2html/m2html.m looks
      % in /usr/local/bin and /opt/homebrew/bin). Without dot, graph.png goes
      % stale, so install Graphviz before regenerating the function pages.
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
         'template', 'blue2_baseflow', ...    % other template
         'ignored', ignored, ...              % dirs to ignore
         'verbose', 'on' ...
         );
   end
end

function cleanupdemofigures(figsbefore, visibility)
   %CLEANUPDEMOFIGURES Delete new figures and restore hidden figure handles.
   %
   %  cleanupdemofigures(figsbefore, visibility) deletes every figure that
   %  is not in figsbefore and sets the HandleVisibility of the figures in
   %  figsbefore back to the saved values in visibility.

   % Delete only the figures opened after the snapshot, then restore the
   % handles makedocs hid during the export.
   openfigs = findall(groot, 'Type', 'figure');
   delete(openfigs(~ismember(openfigs, figsbefore)))
   isopen = isgraphics(figsbefore);
   set(figsbefore(isopen), {'HandleVisibility'}, visibility(isopen))
end
