function makedocs()
%MAKEDOCS publish bfra_gettingStarted.m as index.html for GitPages

% Note: the repo is configured to publish from docs/ and the default action
% publishes index.html using jekyll. For custom builds, use a .nojekyll file 

activate m2html

testrun = false;

thispath = fileparts(mfilename('fullpath'));

% next two are for m2html. note, m2html uses relative paths.
ignored = {'.git','.github','testbed'};
mfilepath = fullfile('+bfra');
% mfilepath = fullfile(fileparts(thispath),'+bfra');

if testrun == true
   htmlpath = fullfile(fileparts(thispath),'testbed/docs/html');
   m2htmlpath = fullfile(fileparts(thispath),'testbed/docs/m2html');
else
   htmlpath = fullfile(thispath,'html');
   m2htmlpath = fullfile(thispath,'m2html');
end

% matlab pulish opts
mpubopts = struct( ...
   'format','html', ...
   'outputDir',htmlpath, ...
   'useNewFigure',false ...
   );

% % publish the standard docs using matlab's publish
% publish(fullfile(thispath,'bfra_welcome.m'),mpubopts);
% publish(fullfile(thispath,'bfra_gettingStarted.m'),mpubopts);
% % publish(fullfile(thispath,'bfra_demo.m'),mpubopts);
% publish(fullfile(thispath,'bfra_contents.m'),mpubopts);
% 
% % for github actions the landing page must be saved as index.html
% copyfile(fullfile(htmlpath,'bfra_gettingStarted.html'),fullfile(thispath,'index.html'));

% not sure if other files can also be supported, if so:
% copyfile('html/bfra_demo.html','bfra_demo.html');


%% publish the function documentation using m2html

m2html( ...
   'mfiles',mfilepath, ...             % source dir where the files live
   'htmldir',m2htmlpath, ...           % dest dir where the html files go
   'recursive','off', ...              % recurse through the source dir
   'source','on', ...                  % include source code or not
   'download','off', ...               % include link to download each file
   'syntaxHighlighting','on', ...      % source code syntax hightlight
   'globalHypertextLinks','off', ...   % hyperlinks among other matlab folders
   'graph','on', ...                   % graphviz dependency graph
   'indexFile','function_index', ...   % basename of the HTML index file
   'template','blue', ...              % other template
   'ignored',ignored, ...              % dirs to ignore
   'verbose','on' ...
   );

% % this is how m2html installs its own docs:
% m2html( ...
%    'mfiles','m2html', ...
%    'htmldir','doc', ...
%    'recursive','on', ...
%    'global','on', ...
%    'graph','on' ...
%    );


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


% build a doc search database
% builddocsearchdb(fullfile(thispath,'html'))


