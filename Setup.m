function varargout = Setup(varargin)
%SETUP install the toolbox, set paths etc.
%
%  msg = Setup() without any inputs adds toolbox paths to the search path.
%  Equivalent to Setup('addpath').
% 
%  msg = Setup('install') adds toolbox paths to the search path, sets default
%  toolbox preferences, and runs a dependency check. To see preferences, try
%  getpref('baseflow').
% 
%  msg = Setup('uninstall') removes all toolbox paths from the search path
%  and unsets bfra toolbox preferences. Does not delete the toolbox directory.
% 
%  msg = Setup('dependencies') generates a list of function and toolbox
%  dependencies and determines which ones are not on the current search path.
%  Results are returned in the msg output.
% 
%  msg = Setup('addpath') adds all toolbox paths to the search path. Does not
%  modify any pathdef.m files or userpath.
%  
%  msg = Setup('rmpath') removes all toolbox paths from the search path. Does
%  not modify any pathdef.m files or userpath.
% 
% See also bfra.util.dependencies

% NOTE genpath ignores folders named private, folders that begin with the @
% character (class folders), folders that begin with the + character (package
% folders), folders named resources, or subfolders within any of these.

% ------------
% parse inputs
% ------------

% temporarily turn off warnings about paths not already being on the path
warning off

% at most one argument
narginchk(0,1)

% valid input options
validopts = {'install','uninstall','dependencies','addpath','rmpath'};

% parse provided option
if nargin < 1 

   option = 'addpath'; 

elseif nargin == 1

   option = validatestring(varargin{:},validopts,mfilename,'option',1);

end

% if 'install' is requested but the toolbox is installed, ask the user
if strcmp(option,'install') && ispref('baseflow','installed')
   if getpref('baseflow','installed')
      msg = '\n * bfra toolbox is installed, press ''y'' to re-install ';
      msg = [msg 'or any other key to abort *\n'];
      str = input(msg,'s');
      if ~strcmp(str,'y')
         return
      end
   end
elseif strcmp(option,'addpath') && ~ispref('baseflow','installed')
   % message that toolbox is not installed but paths are being added
   % only difference between install and addpath is the dependency check
   % assume the user doesn't care, maybe they removed the prefs, add the paths
end

% ------------
% switch yard
% ------------

% call the appropriate function for the requested option
switch option

   case {'install','uninstall'}

      msg = manageinstall(option);

   case {'addpath','rmpath'}

      msg = managepaths(option);

   case {'setpref','getpref','rmprefs'}
      
      msg = manageprefs(option);

   case {'dependencies'}

      msg = managedependencies(option);
end

% -----------
% final steps
% -----------
warning on % turn warning back on

% return msg if requested
if nargout == 1
   varargout{1} = msg;
end

% finished - below here implements the requested option


%% implement the Setup option

% MANAGE INSTALL
function msg = manageinstall(option)

if strcmp(option,'install')

    % display install message
   fprintf('\n * installing baseflow toolbox ... *\n');

   % init the msg
   msg.install = true;

   % init the prefs
   msg = inittoolboxprefs(msg);

   % add toolbox paths
   msg = addtoolboxpaths(msg);

   % check dependencies
   msg = checkdependencies(msg);

   % update the prefs
   if ispref('baseflow','installed')
      setpref('baseflow','installed',true)
   end

   fprintf(' * baseflow toolbox activated *\n'); % display install message
   fprintf(' * try ''getpref(''baseflow'')'' to see current preferences *\n\n'); % display install message
   

elseif strcmp(option,'uninstall')

   % display un-install message
   fprintf('\n * un-installing baseflow toolbox ... *\n');

   % init the msg
   msg.uninstall = true;

   % remove toolbox paths
   msg = rmtoolboxpaths(msg);

   % remove toolbox preferences
   msg = rmtoolboxprefs(msg);

   % display a message that uninstall does not delete the toolbox directories
   fprintf(' * baseflow toolbox uninstalled *\n');
   fprintf(' * to delete the toolbox, try ''rm -r /path/to/this/toolbox'' *\n');
   fprintf(' * or just delete the parent folder *\n\n');

end

% MANAGE PATHS
function msg = managepaths(option)

if strcmp (option,'addpath')

   % init the msg
   msg.addpath = true;

   % display message (entry and exit point)
   fprintf('\n * adding baseflow toolbox paths to search path *\n\n');

   % if the toolbox was 'uninstalled' and then later 'addpath' requested,
   % rebuild the pref's 
   if ~ispref('baseflow')
      inittoolboxprefs;
   end

   % add toolbox paths to userpath
   msg = addtoolboxpaths(msg);

elseif strcmp (option,'rmpath')

   % init the msg
   msg.addpath = true;

   % display message (entry and exit point)
   fprintf('\n * removing baseflow toolbox paths from search path *\n\n');

   % remove toolbox paths from userpath
   msg = rmtoolboxpaths(msg);

end


% MANAGE PREFS
function msg = manageprefs(option)

if strcmp (option,'initprefs')

   % display message
   fprintf('\n * initializing baseflow toolbox preferences *\n');

   % set the prefs
   msg = inittoolboxprefs();

elseif strcmp (option,'rmprefs')

   % display message
   fprintf('\n * removing baseflow toolbox preferences *\n');

   % remove toolbox preferences
   msg = rmtoolboxprefs();

end


% MANAGE DEPS
function msg = managedependencies(option)

if strcmp(option,'dependencies')

   msg.checkdependencies = true;
   msg = checkdependencies(msg);

% elseif strcmp(option,'dependencies')

end


% -----------------
% UTILITY FUNCTIONS
% -----------------

function msg = addtoolboxpaths(varargin)
%ADDTOOLBOXPATHS
narginchk(0,1); if nargin==1; msg = varargin{1}; end
% get the path to the toolbox
thispath = fileparts(mfilename('fullpath'));
% add paths containing source code
addpath(genpath(thispath),'-end');
% remove namespace +bfra and git directories from path
rmpath(genpath(fullfile(thispath,'+bfra')));
rmpath(genpath(fullfile(thispath,'.git')));
setpref('baseflow','install_directory',thispath)
setpref('baseflow','installed',true)
msg.addpath = true;


function msg = rmtoolboxpaths(varargin)
%RMTOOLBOXPATHS
narginchk(0,1); if nargin==1, msg = varargin{1}; end
rmpath(genpath(fileparts(mfilename('fullpath'))));
% update the prefs
setpref('baseflow','install_directory',false)
setpref('baseflow','installed',false)
% setpref('baseflow','dependencies_checked',false) - keep this on rmpath, it
% indicates whether the dependencies were satisfied on install or the last check
msg.rmpath = true;


function msg = inittoolboxprefs(varargin)
%INITTOOLBOXPREFS
narginchk(0,1); if nargin==1; msg = varargin{1}; end
if ispref('baseflow')
   rmpref('baseflow');
end
addpref('baseflow','version',bfra.version)
% prefs = {'installed','install_directory','pathdef_filename','dependencies_checked'};
prefs = {'installed','install_directory','dependencies_checked','Curve_Fitting_Toolbox','Statistics_Toolbox'};
for n = 1:numel(prefs)
   if ~ispref('baseflow',prefs{n})
      addpref('baseflow',prefs{n},false)
   end
end
msg.initprefs = true;


function msg = rmtoolboxprefs(varargin)
%RMTOOLBOXPREFS
narginchk(0,1); if nargin==1; msg = varargin{1}; end
if ispref('baseflow')
   rmpref('baseflow');
end
msg.rmprefs = true;


function msg = checkdependencies(varargin)
%CHECKDEPENDENCIES

narginchk(0,1); if nargin==1; msg = varargin{1}; end

% this step should resolve any errors due to missing function dependencies.
% all required functions should be included in the toolbox, but this can be used
% to check in case any errors come up. It also returns a list of the required
% products. The list will include the symbolic math toolbox and signal
% processing toolbox, but they are not actually required, its a bug in the
% built-in function. 

% display message
if isfield(msg,'install') && msg.install == true
   fprintf(' * checking dependencies ... this can be slow *\n'); % intermediate
else
   fprintf('\n * checking dependencies ... this can be slow *\n'); % entry point
end

% get the path to the toolbox
thispath = fileparts(mfilename('fullpath'));

% add toolbox prefs
addtoolboxpaths();

% default to not satisfied
if ~ispref('baseflow','dependencies_checked')
   addpref('baseflow','dependencies_checked',false)
else
   setpref('baseflow','dependencies_checked',false)
end

% get all unique dependencies
funcname = fullfile(thispath,'docs','bfra_demo.m');
report = bfra.util.dependencies(funcname,'check');
% report = bfra.util.dependencies('docs/bfra_demo.m','check');
msg.function_dependencies = report.function_dependencies;
msg.missing_dependencies = report.missing_dependencies;
msg.product_dependencies = report.product_dependencies;

if ischar(msg.missing_dependencies) && ...
      strcmp(msg.missing_dependencies,'all dependencies are installed')
   if isfield(msg,'install') && msg.install == true
      fprintf(' * dependencies satisfied *\n');
   else
      fprintf(' * dependencies satisfied *\n\n'); % exit point
   end
   setpref('baseflow','dependencies_checked',true)
else
   fprintf(' * baseflow toolbox dependencies not satisfied ... *\n');
   fprintf(' * see msg.missing_dependencies for a list of required dependencies not found on the search path *\n');
   fprintf(' * to resolve, try downloading them from https://github.com/mgcooper/matfunclib *\n');
   fprintf(' * or raise an issue at https://github.com/mgcooper/baseflow *\n');
   setpref('baseflow','dependencies_checked',false)
end

msg.dependencies = true;

% add installed toolboxes to prefs
required_toolboxes = {'Curve_Fitting_Toolbox','Statistics_Toolbox'};
for n = 1:numel(required_toolboxes)
   check = bfra.util.getFeatureName(required_toolboxes{n});
   if ispref('baseflow',required_toolboxes{n})
      setpref('baseflow',required_toolboxes{n},check{3});
   else
      addpref('baseflow',required_toolboxes{n},check{3});
   end
end

% % for users - if the required_toolboxes check fails, it is possible that on
% your machine the second output of bfra.util.getFeatureName is different than
% the two defined above. In that case, run the loop below and raise an issue on
% github or submit a pull request using the fork,clone,branch workflow.

% v = ver % Get all your version info into one variable.
% for k = 1 : length(ver)
% 	thisToolboxName = v(k).Name;
% 	fprintf('Checking on %s..\n', thisToolboxName);
% 	toolboxInfo = bfra.util.getFeatureName(thisToolboxName);
% 	fprintf('    "%s" is "%s"\n', toolboxInfo{1}, toolboxInfo{2});
% 	if toolboxInfo{3} == 1
% 		fprintf('        You currently have a license to use %s.\n', toolboxInfo{1});
% 	else
% 		fprintf('        You do not currently have a license to use %s.\n', toolboxInfo{1});
% 	end
% end

