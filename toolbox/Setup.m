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
   %  and unsets baseflow toolbox preferences. Does not delete the toolbox directory.
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
   % See also baseflow.internal.dependencies

   % NOTE genpath ignores folders named private, folders that begin with the @
   % character (class folders), folders that begin with the + character (package
   % folders), folders named resources, or subfolders within any of these.

   % temporarily turn off warnings
   originalWarningState = warning;
   cleanupObj = onCleanup(@() warning(originalWarningState));

   if inoctave
      warning('off','Octave:rmpath:DirNotFound') % may not work
      warning('off','Octave:addpath-pkg')
      warning('off','Octave:shadowed-function')
   else
      warning('off','MATLAB:rmpath:DirNotFound')
      warning('off','MATLAB:mpath:packageDirectoriesNotAllowedOnPath')
   end

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
   if strcmp(option, 'install') && ispref('baseflow', 'installed')
      if getpref('baseflow', 'installed')
         msg = '\n * baseflow toolbox is installed, press ''y'' to re-install ';
         msg = [msg 'or any other key to abort *\n'];
         str = input(msg, 's');
         if ~strcmp(str, 'y')
            return
         end
      end
   elseif strcmp(option,'addpath') && ~ispref('baseflow','installed')
      % Message that toolbox is not installed but paths are being added. Only
      % difference between install and addpath is the dependency check assume
      % the user doesn't care, maybe they removed the prefs, add the paths
   end

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

   % Load OCTAVE packages
   if inoctave
      pkg load struct
      pkg load statistics
      pkg load tablicious
      pkg load optim
      pkg load statistics-bootstrap
      pkg load financial
      % setenv ("OCTAVE_LATEX_DEBUG_FLAG", "1")
      % setenv ("OCTAVE_LATEX_BINARY", )
      % setenv ("OCTAVE_DVIPNG_BINARY", )
      % setenv ("OCTAVE_DVISVG_BINARY", )
   end

   % return msg if requested
   if nargout == 1
      varargout{1} = msg;
   end
end

% Helper
function tf = inoctave()
   tf = (exist ("OCTAVE_VERSION", "builtin") > 0);
end

%% implement the Setup option
function msg = manageinstall(option)
   % MANAGE INSTALL

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

      % display install message
      fprintf(' * baseflow toolbox activated *\n');
      fprintf(' * try ''getpref(''baseflow'')'' to see current preferences *\n\n');

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
end

function msg = managepaths(option)
   % MANAGE PATHS
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
end

function msg = managedependencies(option)
   % MANAGE DEPS
   if strcmp(option,'dependencies')

      msg.checkdependencies = true;
      msg = checkdependencies(msg);

      % elseif strcmp(option,'dependencies')
   end
end

% -----------------
% UTILITY FUNCTIONS
% -----------------

function msg = addtoolboxpaths(varargin)
   %ADDTOOLBOXPATHS Add toolbox paths containing source code to the path
   narginchk(0,1); if nargin==1; msg = varargin{1}; end
   % get the path to the toolbox and add paths containing code
   thispath = fileparts(mfilename('fullpath'));
   addpath(genpath(thispath),'-end');
   % remove namespace +baseflow and git directories from path
   % rmpath(genpath(fullfile(thispath,'+baseflow')));
   rmpath(genpath(fullfile(thispath,'.git')));
   setpref('baseflow','install_directory',thispath)
   setpref('baseflow','installed',true)
   msg.addpath = true;

   % In Octave, make private folders inside packages accessible.
   if inoctave
      addpath(fullfile(thispath, '+baseflow', 'private'));
      addpath(fullfile(thispath, '+baseflow', '+internal', 'private'));
   end
end

function msg = rmtoolboxpaths(varargin)
   %RMTOOLBOXPATHS Remove toolbox paths and update preference group.
   narginchk(0,1); if nargin==1, msg = varargin{1}; end
   rmpath(genpath(fileparts(mfilename('fullpath'))));
   setpref('baseflow', 'install_directory', false)
   setpref('baseflow', 'installed', false)
   % setpref('baseflow','dependencies_checked',false) - keep this on rmpath,
   % it indicates whether the dependencies were satisfied on install or the
   % last check.
   msg.rmpath = true;
end


function msg = inittoolboxprefs(varargin)
   %INITTOOLBOXPREFS
   narginchk(0,1); if nargin==1; msg = varargin{1}; end
   if ispref('baseflow')
      rmpref('baseflow');
   end
   addpref('baseflow', 'version', baseflow.internal.version())
   % note: 'pathdef_filename' removed from prefs
   if inoctave == true
      prefs = {'installed','install_directory','octave_install', ...
         'dependencies_checked','Struct_Package','Tablicious_Package', ...
         'Statistics_Package'};
   else
      prefs = {'installed','install_directory','octave_install', ...
         'dependencies_checked','Curve_Fitting_Toolbox','Statistics_Toolbox'};
   end

   for n = 1:numel(prefs)
      if ~ispref('baseflow',prefs{n})
         addpref('baseflow',prefs{n},false)
      end
   end
   if inoctave == true
      setpref('baseflow','octave_install',true);
   end
   msg.initprefs = true;
end

function msg = rmtoolboxprefs(varargin)
   %RMTOOLBOXPREFS
   narginchk(0,1); if nargin==1; msg = varargin{1}; end
   if ispref('baseflow')
      rmpref('baseflow');
   end
   msg.rmprefs = true;
end

function msg = checkdependencies(varargin)
   %CHECKDEPENDENCIES

   narginchk(0,1); if nargin==1; msg = varargin{1}; end

   % 26 Apr 2023 - removed dependency check after moving all dependencies to
   % sub-package namespace folders and running matlab built in dependency report
   % and resolving all dependencies.
   fprintf(' * all dependencies are included in package namespace folders *\n');
   fprintf([' * if users encounter missing dependencies, please open a ' ...
      'ticket at https://github.com/mgcooper/baseflow/issues * \n']);

   return

   % this step should resolve any errors due to missing function
   % dependencies. all required functions should be included in the toolbox,
   % but this can be used to check in case any errors come up. It also
   % returns a list of the required products. The list will include the
   % symbolic math toolbox and signal processing toolbox, but they are not
   % actually required, its a bug in the built-in function.

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
   funcname = fullfile(thispath,'docs','baseflow_demo.m');
   report = baseflow.internal.dependencies(funcname,'check');
   % report = baseflow.dependencies('docs/baseflow_demo.m','check');
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
      fprintf([' * see msg.missing_dependencies for a list of required ' ...
         'dependencies not found on the search path *\n']);
      fprintf([' * to resolve, try downloading them from ' ...
         'https://github.com/mgcooper/matfunclib *\n']);
      fprintf(' * or raise an issue at https://github.com/mgcooper/baseflow *\n');
      setpref('baseflow','dependencies_checked',false)
   end

   msg.dependencies = true;

   % add installed toolboxes to prefs
   required_toolboxes = {'Curve_Fitting_Toolbox','Statistics_Toolbox'};
   for n = 1:numel(required_toolboxes)
      check = getFeatureName(required_toolboxes{n});
      if ispref('baseflow',required_toolboxes{n})
         setpref('baseflow',required_toolboxes{n},check{3});
      else
         addpref('baseflow',required_toolboxes{n},check{3});
      end
   end

   % % for users - if the required_toolboxes check fails, it is possible that on
   % your machine the second output of getFeatureName is different than
   % the two defined above. In that case, run the loop below and raise an issue on
   % github or submit a pull request using the fork,clone,branch workflow.

   % v = ver % Get all your version info into one variable.
   % for k = 1 : length(ver)
   % 	thisToolboxName = v(k).Name;
   % 	fprintf('Checking on %s..\n', thisToolboxName);
   % 	toolboxInfo = getFeatureName(thisToolboxName);
   % 	fprintf('    "%s" is "%s"\n', toolboxInfo{1}, toolboxInfo{2});
   % 	if toolboxInfo{3} == 1
   % 		fprintf('You currently have a license to use %s.\n', toolboxInfo{1});
   % 	else
   % 		fprintf('You do not currently have a license to use %s.\n', toolboxInfo{1});
   % 	end
   % end
end

function OUT = getFeatureName(fullname)
   % getFeatureName - translates a toolbox name from 'ver' into
   % a feature name and vice versa, also checks license availability
   %
   % Syntax:
   %   getFeatureName(fullname)
   %
   % Inputs:
   %   fullname:       character vector of toolbox name as listed in ver
   %                   output (optional, if none given all features are
   %                   listed)
   %
   % Outputs:
   %   translation:    cell array with clear name, feature name and license
   %                   availability
   %
   %-------------------------------------------------------------------------
   % Version 1.1
   % 2018.09.04        Julian Hapke
   % 2020.05.05        checks all features known to current release
   %-------------------------------------------------------------------------
   assert(nargin < 2, 'Too many input arguments')
   % defaults
   checkAll = true;
   installedOnly = false;
   if nargin
      checkAll = false;
      installedOnly = strcmp(fullname, '-installed');
   end
   if checkAll || installedOnly
      allToolboxes = com.mathworks.product.util.ProductIdentifier.values;
      nToolboxes = numel(allToolboxes);
      out = cell(nToolboxes, 3);
      for iToolbox = 1:nToolboxes
         marketingName = char(allToolboxes(iToolbox).getName());
         flexName = char(allToolboxes(iToolbox).getFlexName());
         out{iToolbox, 1} = marketingName;
         out{iToolbox, 2} = flexName;
         out{iToolbox, 3} = license('test', flexName);
      end
      if installedOnly
         installedToolboxes = ver;
         installedToolboxes = {installedToolboxes.Name}';
         out = out(ismember(out(:,1), installedToolboxes),:);
      end
      if nargout
         OUT = out;
      else
         out = [{'Name', 'FlexLM Name', 'License Available'}; out];
         disp(out)
      end
   else
      productidentifier = com.mathworks.product.util.ProductIdentifier.get(fullname);
      if (isempty(productidentifier))
         warning('"%s" not found.', fullname)
         OUT = cell(1,3);
         return
      end
      feature = char(productidentifier.getFlexName());
      OUT = [{char(productidentifier.getName())} {feature} {license('test', feature)}];
   end
end
