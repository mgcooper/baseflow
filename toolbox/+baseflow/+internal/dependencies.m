function report = dependencies(funcname,option)
   % DEPENDENCIES Generate function and product dependencies for function.
   %
   %  Input
   %     funcname = char of any function name
   %
   %  Output
   %     funclist = table with column of all functions that input funcname
   %     depends on, the functions that each of those depends on, and the
   %     products that each of those depends on.
   %
   %  Example
   %
   %    % Generate a dependency report.
   %    funcname = 'my_pkg_demo.m';
   %    report = tbx.internal.dependencies(funcname, 'report');
   %
   %    % Note: if returned as table:
   %    deps = report.function_dependencies
   %
   %    % Sort the list:
   %    deps = cellfun(@(x)strrep(x,[fileparts(x) filesep],''),deps,'uni',0);
   %    deps = sort(string(deps));
   %    report.function_dependencies = deps;
   %
   %    % Save the list:
   %    fsave = fullfile(pwd, 'dependencies.mat');
   %    save(fsave, 'report');
   %
   %    % Save as a textfile in the top-level:
   %    fsave = strrep(fsave, 'mat', 'txt');
   %    fid = fopen(fsave,'w');
   %    n = 0;
   %    while n<numel(deps)
   %       n = n+1;
   %       fprintf(fid,'%s\n',deps{n});
   %    end
   %    fclose(fid);
   %
   % See also: Setup

   % Use this to generate a list of all functions in the package, then cycle
   % over all of them and find the dependencies:
   %
   % funcpath = fileparts(which('pkg.func'));
   % funclist = getlist(funcpath,'.m');
   

   [pkgname, pkgfolder] = mpackagename();

   % valid options
   validopts = ["all","missing","installed","resolve","report","check"];
   for n = 1:numel(validopts)
      opts.(validopts(n)) = option == validopts(n);
   end

   % use this to test a particular function
   if nargin == 0
      funcname = '';
   end

   % this loads the saved dependencies.mat file and checks against util/
   if opts.check == true
      report = dependencycheck(pkgfolder);
      return
   end

   funcpath = fileparts(which(funcname));
   [funclist,prodlist] = matlab.codetools.requiredFilesAndProducts(funcname);
   funclist = transpose(funclist);
   prodlist = transpose(prodlist);

   if opts.all == true
      % return a table of all dependencies
      report = cell2table(funclist,'VariableNames',{'function_dependencies'});
   elseif opts.report == true
      report = getdependencyreport(funclist,prodlist,funcname,pkgfolder);
   elseif opts.missing == true
      report = getmissingdependencies(funclist,funcname,pkgname,pkgfolder);
   elseif opts.installed == true
      % subfunction getinstalleddependencies is missing, check baseflow tbx.
      % report = getinstalleddependencies(funclist);
   elseif opts.resolve == true
      report = resolvedependencies(funclist,funcname,pkgfolder,pkgname);
   end
end

function report = getdependencyreport(funclist,prodlist,funcname,pkgfolder)

   % get a list of dependencies that are not toolbox functions, i.e. those that
   % need to be included in util/
   % report = funclist;
   skip = {pkgfolder, funcname, 'ExtractNameVal', 'Cupid'};
   keep = true(numel(funclist),1);
   for n = 1:numel(funclist)
      keep(n) = ~ismember(funclist{n},skip);
   end
   report.function_dependencies = funclist(keep);
   report.product_dependencies = prodlist;
   % report = report(keep);
end

function report = dependencycheck(pkgfolder)
   load(fullfile(installpath(), pkgfolder, 'private', 'dependencies.mat'), 'report')
   deps = report.function_dependencies;
   deps = deps(~isfile(fullfile(installpath(), 'util', deps)));
   deps = deps(~isfolder(strrep(fullfile(installpath(), 'util', deps),'.m','')));
   % convert to table and return
   if isempty(deps)
      report.missing_dependencies = 'all dependencies are installed';
   else
      report.missing_dependencies = deps;
   end
end

function report = getmissingdependencies(funclist,funcname,pkgname,pkgfolder)

   % remove functions in the toolbox first, leave the ones in util/ so they can
   % be compared here if needed for debugging.
   missing = funclist;
   % Also remove the 'cupid' toolbox and 'ExtractNameVal' functions that get
   % picked up as dependent but are not. What remains after this is functions
   % that are either in util/ or need to be moved there.
   skip = {pkgfolder, funcname, 'ExtractNameVal', 'Cupid'};
   keep = true(numel(missing),1);
   for n = 1:numel(missing)
      keep(n) = ~ismember(missing{n},skip);
   end
   missing = missing(keep);

   % now remove ones that are in util.
   skip = {fullfile(pkgname, 'util')};
   keep = true(numel(missing),1);
   for n = 1:numel(missing)
      keep(n) = ~ismember(missing{n},skip);
   end
   missing = missing(keep);

   % % since I use addpath(...,'-end'), the dependency check finds functions in
   % the main function folder not the ones in pkgname/util.
   % now check if funclist ismember paths to versions elsewhere that are in
   % util. What remains are missing.
   keep = true(numel(missing),1);
   for n = 1:numel(missing)
      [~,funcname] = fileparts(missing{n});
      allfuncs = which(funcname,'-all');
      if any(ismember(allfuncs,fullfile(pkgname,'util',funcname)))
         keep(n) = false;
      end
   end
   missing = missing(keep);

   % convert to table and return
   report.function_dependencies = funclist;
   if isempty(missing)
      report.missing_dependencies = 'all dependencies are installed';
   else
      report.missing_dependencies = missing;
   end
end

%% internal use
function report = resolvedependencies(funclist,funcname,pkgfolder,pkgname)

   % cycle through the dependent functions and copy them to util/

   % NOTE: this is for private use, it won't work if you don't have the
   % functions on your local computer. Please contact me at matt.cooper@pnnl.gov
   % if you have any trouble running this toolbox or if any function
   % dependencies are missing from the toolbox. Alternatively, look for the
   % missing functions in https://github.com/mgcooper/matfunclib (I suggest the
   % dev branch). Thank you.

   % TODO: add method to clone from https://github.com/mgcooper/matfunclib

   report = getmissingdependencies(funclist,funcname,pkgname,pkgfolder);

   if ischar(report.missing_dependencies) && ...
         strcmp(report.missing_dependencies,'all dependencies are installed')
      return
   else
      for n = 1:numel(report.missing_dependencies)
         [~,fname,ext] = fileparts(report.missing_dependencies{n});
         destpath = fullfile(installpath(),'util',[fname,ext]);
         copyfile(report.missing_dependencies{n},destpath);
      end
   end

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
