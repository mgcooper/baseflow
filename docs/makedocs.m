function makedocs(varargin)
%MAKEDOCS publish bfra_gettingStarted.m as index.html for GitPages

% Note: the repo is configured to publish from docs/ and the default action
% publishes index.html using jekyll. For custom builds, use a .nojekyll file

% three options: publish example docs, function docs, or build docsearch db
opts = bfra.util.optionParser({'examples','functions','docsearch'},varargin(:));

% set paths 
thispath = fileparts(mfilename('fullpath'));
basepath = fileparts(thispath);

testrun = false;
if testrun == true
   docspath = fullfile(basepath, 'testbed', 'docs');
else
   docspath = thispath;
end

% nest m2html stuff in html/ to easily distinguish it from matlab publish stuff
htmlpath = fullfile(docspath, 'html');
m2htmlpath = fullfile(htmlpath, 'm2html');

% matlab publish opts
mpubopts = struct( ...
   'format', 'html', ...
   'outputDir', htmlpath, ...
   'useNewFigure', false ...
   );

%% build a doc search database
 
if opts.docsearch == true
   builddocsearchdb(htmlpath)
end

%% publish the example documentation using publish

if opts.examples == true
   
   % publish the standard docs using matlab's publish
   publish(fullfile(docspath, 'bfra_welcome.m'), mpubopts);
   publish(fullfile(docspath, 'bfra_gettingStarted.m'), mpubopts);
   publish(fullfile(docspath, 'bfra_contents.m'), mpubopts);
   publish(fullfile(docspath, 'bfra_theory_contents.m'), mpubopts);
   publish(fullfile(docspath, 'bfra_examples_contents.m'), mpubopts);

   % for github actions the landing page must be saved as index.html
   copyfile(fullfile(htmlpath, 'bfra_gettingStarted.html'), ...
      fullfile(docspath, 'index.html'));

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

