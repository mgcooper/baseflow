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
% See also bfra.dependencies

% NOTE genpath ignores folders named private, folders that begin with the @
% character (class folders), folders that begin with the + character (package
% folders), folders named resources, or subfolders within any of these.

% TODO: change msg.() to msg.entrypoint = <>

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

   % % this would force install, but that's going overboard
   % if ispref('baseflow')
   %    % default behavior adds toolbox paths to the search path
   %    option = 'addpath'; 
   % else
   %    % unless the toolbox isn't installed
   %    option = 'install';
   % end

elseif nargin == 1

   option = validatestring(varargin{:},validopts,mfilename,'option',1);

   % % optionParser style would support more than one option per call
   % for n = 1:numel(validopts)
   %    opts.(validopts(n)) = option == validopts(n);
   % end
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
   
   % save the path
   % msg = savetoolboxpaths(msg); % let the user call 'savepath' instead

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

   % delete toolbox pathdef file (only looks in this directory)
   % msg = deltoolboxpaths(msg); % don't mess with savepath

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

elseif strcmp (option,'savepath')

   % removed support for savepath and delpath - too easy to mess up the
   % userpath and/or pathdef file.

%    % init the msg
%    msg.savepath = true;
% 
%    % display message
%    fprintf('\n * saving baseflow toolbox paths to local pathdef.m file ... *\n');
%    fprintf(' * use matlab built-in ''savepath'' to add toolbox paths to your userpath *\n\n ');
% 
%    % save the current userpath
%    if ispref('baseflow')
%       setpref('baseflow','userpath',userpath)
%    else
%       addpref('baseflow','userpath',userpath)
%    end
% 
%    % add toolbox paths
%    msg = addtoolboxpaths(msg);
% 
%    % save toolbox paths to local pathdef.m file
%    msg = savetoolboxpaths(msg);

elseif strcmp (option,'delpath')

%    % init the msg
%    msg.delpath = true;
% 
%    % display message
%    fprintf('\n * deleting local pathdef.m file ... *\n');
% 
%    % remove toolbox paths from userpath and delete toolbox local pathdef.m file
%    msg = deltoolboxpaths(msg);
% 
%    % reset the userpath 
%    if ispref('baseflow','userpath')
%       if strcmp(getpref('baseflow','userpath'),userpath)
%          userpath(getpref('baseflow','userpath'))
%       end
%    else
%       userpath('reset');
%    end

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
prefs = {'installed','install_directory','dependencies_checked'};
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
funcname = fullfile(thispath,'docs','bfra_demo.m'); %'bfra_demo.mlx';
[funclist,prodlist] = bfra.util.dependencies(funcname,'missing');

msg.functionDependencies = funclist;
msg.productDependencies = prodlist;

if ischar(msg.functionDependencies) && ...
      strcmp(msg.functionDependencies,'all dependencies are installed')
   if isfield(msg,'install') && msg.install == true
      fprintf(' * dependencies satisfied *\n');
   else
      fprintf(' * dependencies satisfied *\n\n'); % exit point
   end
   setpref('baseflow','dependencies_checked',true)
else
   fprintf(' * baseflow toolbox dependencies not satisfied ... *\n');
   fprintf(' * see msg.functionDependencies for a list of required dependencies not found on the search path *\n');
   fprintf(' * to resolve, try downloading them from https://github.com/mgcooper/matfunclib *\n');
   fprintf(' * or raise an issue at https://github.com/mgcooper/baseflow *\n');
   setpref('baseflow','dependencies_checked',false)
end

msg.dependencies = true;


% function msg = savetoolboxpaths(varargin)
% %SAVETOOLBOXPATHS
% narginchk(0,1); if nargin==1; msg = varargin{1}; end
% % save the current userpath
% if ispref('baseflow')
%    setpref('baseflow','userpath',userpath)
% else
%    addpref('baseflow','userpath',userpath)
% end
% pathfile = fullfile(fileparts(mfilename('fullpath')),'pathdef.m');
% savepath(pathfile);
% msg.savepath = true;
% setpref('baseflow','installed',true)
% setpref('baseflow','pathdef_filename',pathfile)
% msg.savepath = true;


% function msg = deltoolboxpaths(varargin)
% %DELTOOLBOXPATHS
% narginchk(0,1); if nargin==1; msg = varargin{1}; end
% if isfile(fullfile(fileparts(mfilename('fullpath')),'pathdef.m'))
%    delete(fullfile(fileparts(mfilename('fullpath')),'pathdef.m'));
%    if isfield(msg,'uninstall') && msg.uninstall == true
%       fprintf(' * local pathdef.m file deleted *\n'); % intermediate
%    else
%       fprintf(' * local pathdef.m file deleted *\n\n'); % exit point
%    end
% else
%    if isfield(msg,'uninstall') && msg.uninstall == true
%       fprintf(' * no local pathdef.m file found *\n'); % intermediate
%    else
%       fprintf(' * no local pathdef.m file found *\n\n'); % exit point
%    end
% end
% setpref('baseflow','pathdef_filename',false);
% % setpref('baseflow','installed',false) - let 'uninstall' and 'rmpath' do this
% % reset the userpath
% if ispref('baseflow','userpath') 
%    if isempty(userpath)
%       userpath(getpref('baseflow','userpath'))
%    else
%       % the userpath has been reset, ambiguous what to do
%    end
% else
%    userpath('reset') % ambiguous if this is the right choice
% end
% msg.delpath = true;


% run Config, Startup, read .env, etc

% TODO

% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
%  not implemented

% Store the default options as prefs on this machine.
% The user can change these with bfra.setopts.

% This would store the opts in 'opts' which could be saved as a .mat file.
% opts = bfra.setopts;

% % Alternatively, modify bfra.setopts to add the options as custom prefs:
% addpref('baseflow','version','1.0.0');



% % kept this for  now for refrences, but with new setup, helper functions
% should just do what they advertise and logical checks should be performed
% ahead of time to determien what helper functions to call

% % if this is the first time Setup is being run, check dependencies
% if ~ispref('baseflow','installed') % || opts.dependencies == true
% 
%    % add the pref
%    if ~ispref('baseflow','installed')
%       addpref('baseflow','installed',true)
%    else
%       setpref('baseflow','installed',true)
%    end
% 
%    % default to not satisfied
%    if ~ispref('baseflow','dependencies_checked')
%       addpref('baseflow','dependencies_checked',false)
%    end
% 
%    % display install message
%    fprintf('\n * checking dependencies ... *\n\n');
%    
%    % get all unique dependencies
%    funcname = fullfile(thispath,'docs','bfra_demo.m'); %'bfra_demo.mlx';
%    [funclist,prodlist] = bfra.util.dependencies(funcname,'missing');
%    
%    msg.functionDependencies = funclist;
%    msg.productDependencies = prodlist;
%    
%    if msg.functionDependencies == "all dependencies are installed"
%       fprintf(' * dependencies satisfied ... *\n\n');
%       setpref('baseflow','dependencies_checked',true)
%    end
% 
% end


