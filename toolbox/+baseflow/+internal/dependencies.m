function report = dependencies(funcname, option)
   % DEPENDENCIES Report and check function and product dependencies.
   %
   %  Input
   %     funcname = char of any function name, or a cell array of function
   %     names to analyze together. Empty ('') or omitted analyzes every
   %     public function in the +baseflow package.
   %     option = char of one analysis option, listed below.
   %
   %  Output
   %     report = struct or table of dependency results; the fields depend
   %     on the option.
   %
   %  Options
   %     'all'       table of every required file
   %     'report'    struct with function and product dependencies
   %     'missing'   required files that resolve outside this toolbox and
   %                 have no same-named file inside it
   %     'check'     'missing' plus a product comparison against the
   %                 DESCRIPTION MatlabProducts line
   %     'installed' product dependencies and whether each is installed
   %     'resolve'   copy missing .m files into toolbox/+baseflow/private/
   %                 and missing data files into toolbox/data/
   %
   %  Every option analyzes the current code with
   %  matlab.codetools.requiredFilesAndProducts. No option needs a saved
   %  dependencies.mat file.
   %
   %  Example
   %
   %    % Check that the toolbox is self-contained.
   %    report = baseflow.internal.dependencies('', 'check');
   %
   %    % Report the dependencies of one function.
   %    report = baseflow.internal.dependencies('baseflow.fitab', 'report');
   %
   % See also: Setup

   % valid options
   validopts = {'all', 'missing', 'installed', 'resolve', 'report', 'check'};
   if nargin < 2 || isempty(option)
      option = 'report';
   end
   if nargin < 1
      funcname = '';
   end
   option = validatestring(option, validopts, mfilename, 'option', 2);

   % Resolve the target files: named functions, or the whole public API.
   % The public API is +baseflow plus its public +util subpackage;
   % +internal, +deps, and private/ are implementation and vendored code.
   if isempty(funcname)

      pkgfolder = fullfile(toolboxpath(), '+baseflow');
      utilfolder = fullfile(pkgfolder, '+util');
      files = [ ...
         listfiles(pkgfolder, 'aslist', true, 'fullpath', true, 'mfiles', true); ...
         listfiles(utilfolder, 'aslist', true, 'fullpath', true, 'mfiles', true)];

   else
      if ischar(funcname) || isstring(funcname)
         funcname = cellstr(funcname);
      end
      files = cellfun(@which, funcname, 'UniformOutput', false);
      unresolved = cellfun(@isempty, files);
      if any(unresolved)
         error('baseflow:dependencies:unknownFunction', ...
            'function %s was not found on the path', ...
            strjoin(funcname(unresolved), ', '))
      end
   end

   % Resolve names to the vendored copies during the analysis. Put the
   % toolbox paths at the front of the path, and restore the original path
   % afterward. addtoolboxpaths appends with '-end'. On the author's
   % machine, names otherwise resolve to the original un-vendored sources
   % (matfunclib), which add their own dependencies to the closure as
   % false missing files.
   origpath = path();
   restorepath = onCleanup(@() path(origpath));
   addpath(genpath(toolboxpath()));

   % MATLAB does not allow private folders on the path. A call from a folder
   % that cannot see a vendored private copy can still resolve to the
   % original source (for example, a withwarnoff call in an +internal
   % function). The same-name check below marks such a file as satisfied
   % by its vendored copy.

   % Live analysis. requiredFilesAndProducts excludes MathWorks-shipped
   % files, so every returned file is either toolbox code or an external
   % dependency.
   [funclist, prodlist] = matlab.codetools.requiredFilesAndProducts(files);
   funclist = transpose(funclist);
   prodnames = transpose({prodlist.Name});

   % Classify the required files. A file outside the toolbox counts as
   % missing only when no file with the same name ships inside the toolbox,
   % because addtoolboxpaths appends with '-end'. On a machine with the
   % original un-vendored sources on the path (the author's machine, with
   % matfunclib), a dependency resolves to the outside copy. The vendored
   % copy in private/ still satisfies it.
   % The trailing separator keeps a sibling folder such as toolbox-old
   % from matching the toolbox root prefix.
   tbroot = toolboxpath();
   outside = funclist(~startsWith(funclist, [tbroot, filesep]));
   missing = outside(~cellfun(@(f) insidetoolbox(f, tbroot), outside));

   % Deliberately un-vendored references stay out of the missing list.
   % plfitb's 'hanel' method calls r_plfit, which stays external by
   % decision (no license grant; README documents the requirement).
   % requiredFilesAndProducts omits r_plfit where it is not on the path,
   % so list it whenever the analysis includes plfitb.
   knownexternal = {'r_plfit.m'};
   known = cellfun(@(f) ismember(basename(f), knownexternal), missing);
   knownfiles = missing(known);
   missing = missing(~known);
   analyzed = cellfun(@basename, funclist, 'UniformOutput', false);
   if isempty(knownfiles) && ismember('plfitb.m', analyzed)
      knownfiles = knownexternal;
   end

   % Entry points whose external references await the bfra-3kh.25
   % vendor/gate/de-advertise decision (TODO.md, dependency section).
   % requiredFilesAndProducts omits calls it cannot resolve. On a machine
   % without the original sources, those references never appear in the
   % analysis, so this list still reports these entry points on that machine.
   pendingentries = {'loadcalm.m', 'loadghcnd.m', 'loadgrace.m', ...
      'mapbasins.m', 'mapgages.m'};
   pending = pendingentries(ismember(pendingentries, analyzed));

   switch option

      case 'all'
         % return a table of all required files
         report = cell2table( ...
            funclist, 'VariableNames', {'function_dependencies'});

      case 'report'
         report.function_dependencies = funclist;
         report.product_dependencies = prodnames;

      case {'missing', 'check'}
         report.function_dependencies = funclist;
         report.product_dependencies = prodnames;
         report.known_external = knownfiles;
         report.pending_decision = pending;
         if isempty(missing)
            report.missing_dependencies = 'all dependencies are installed';
         else
            report.missing_dependencies = missing;
         end
         if strcmp(option, 'check')
            report = comparedeclaredproducts(report, prodnames);
         end

      case 'installed'
         % report each required product and whether ver() finds it
         v = ver;
         report.product_dependencies = prodnames;
         report.installed = ismember(prodnames, {v.Name});

      case 'resolve'
         report = resolvedependencies(missing, funclist, prodnames, tbroot);
   end
end

function tf = insidetoolbox(f, tbroot)
   % INSIDETOOLBOX True when a file with this name ships in the toolbox.
   tf = ~isempty(dir(fullfile(tbroot, '**', basename(f))));
end

function name = basename(f)
   % BASENAME Return the file name with its extension.
   [~, base, ext] = fileparts(f);
   name = [base, ext];
end

function report = comparedeclaredproducts(report, prodnames)
   % COMPAREDECLAREDPRODUCTS Compare detected products with DESCRIPTION.
   %
   % The DESCRIPTION file at the repo root is the official dependency list.
   % Its MatlabProducts line declares the required MATLAB toolboxes, and its
   % Depends line declares the Octave packages. An installed copy without
   % the repo root has no DESCRIPTION, so this function skips the
   % comparison there.
   descfile = fullfile(projectpath(), 'DESCRIPTION');
   if ~isfile(descfile)
      report.undeclared_products = 'DESCRIPTION not found; not compared';
      return
   end
   txt = fileread(descfile);
   tok = regexp(txt, 'MatlabProducts:\s*([^\n]*)', 'tokens', 'once');
   if isempty(tok)
      report.undeclared_products = 'no MatlabProducts line in DESCRIPTION';
      return
   end
   declared = strtrim(strsplit(tok{1}, ','));

   % Known requiredFilesAndProducts false positives: the analysis reports
   % the Signal Processing and Symbolic Math toolboxes for code that never
   % calls them. No identifier in the flagged files resolves to either
   % product, and CI passes without them installed.
   falsepos = {'Signal Processing Toolbox', 'Symbolic Math Toolbox', 'MATLAB'};
   detected = setdiff(prodnames, falsepos);
   undeclared = setdiff(detected, declared);
   if isempty(undeclared)
      report.undeclared_products = 'all products are declared';
   else
      report.undeclared_products = undeclared;
   end
end

%% internal use
function report = resolvedependencies(missing, funclist, prodnames, tbroot)

   % copy the missing dependent functions into the vendored private folder

   % NOTE: this is for private use, it won't work if you don't have the
   % functions on your local computer. Please contact me at matt.cooper@pnnl.gov
   % if you have any trouble running this toolbox or if any function
   % dependencies are missing from the toolbox. Alternatively, look for the
   % missing functions in https://github.com/mgcooper/matfunclib (I suggest the
   % dev branch). Thank you.

   % TODO: add method to clone from https://github.com/mgcooper/matfunclib

   report.function_dependencies = funclist;
   report.product_dependencies = prodnames;
   if isempty(missing)
      report.missing_dependencies = 'all dependencies are installed';
      return
   end
   report.missing_dependencies = missing;

   % .m files go to the vendored private folder. Data files go to
   % toolbox/data: MATLAB does not search private folders for a bare
   % load('file.mat'), so a data file in private/ stays unreachable.
   mfiles = endsWith(missing, '.m');
   for n = find(mfiles(:)')
      copyfile(missing{n}, fullfile(tbroot, '+baseflow', 'private'));
   end
   for n = find(~mfiles(:)')
      copyfile(missing{n}, fullfile(tbroot, 'data'));
   end

   % Parked WIP: per-function dependency attribution.
   % any functions listed in dependentFunctions may be required for some fringe
   % behavior in the toolbox but the core functionality should

   %%

   % % if the commented loop in baseflow.dependencies.m is used, this is required
   % dependentFunctions = unique(vertcat(allDependencies.function_dependencies{:}));

   % % nearly certain it isn't necessary to cycle over all functions, I may have
   % % added this to figure out which functions were responsible for some
   % % functions that were returned as required but sholdn't be like the Cupid
   % % toolbox
   %
   % Depends = cell(numel(funclist),3);
   % for n = 1:numel(funclist)
   %
   %    % this is needed if getlist is used
   %    % thisfunc = [funcpath filesep funclist(n).name];
   %
   %    thisfunc = funclist{n};
   %    [fl,pl] = matlab.codetools.requiredFilesAndProducts(thisfunc);
   %    fl = transpose(fl);
   %
   %    Depends{n,1} = thisfunc;
   %    Depends{n,2} = fl;
   %    Depends{n,3} = {pl(:).Name}';
   % end
   %
   % Depends = cell2table(Depends,'VariableNames',...
   %    {'function_name','function_dependencies','product_dependencies'});
end
