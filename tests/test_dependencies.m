function tests = test_dependencies
   %TEST_DEPENDENCIES Test the dependency tooling and list agreement.
   %
   % Covers baseflow.internal.dependencies: live analysis, self-containment
   % check, DESCRIPTION product comparison, the resolve file copies, and
   % the Setup('dependencies') report.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Run the check once over the core workflow chain and share it across
   % the tests; the analysis is the slow part. The toolbox ships the core
   % chain as self-contained. The loadflow data loader references
   % un-vendored sources; TODO.md tracks that decision.
   corechain = {'baseflow.getevents', 'baseflow.fitevents', ...
      'baseflow.fitab', 'baseflow.eventfinder', 'baseflow.eventtau', ...
      'baseflow.globalfit', 'baseflow.fitphi'};
   testCase.TestData.report = ...
      baseflow.internal.dependencies(corechain, 'check');

   % Name the small analysis target and the success message once; several
   % tests call the same function and compare against the same message.
   testCase.TestData.smallfunction = 'baseflow.conversions';
   testCase.TestData.installedmessage = 'all dependencies are installed';
end

function test_reportFields(testCase)
   % The check report carries the function, product, missing, and
   % declaration-comparison results.
   returned = sort(fieldnames(testCase.TestData.report));
   expected = sort({'function_dependencies'; 'product_dependencies'; ...
      'known_external'; 'missing_dependencies'; 'undeclared_products'});
   testCase.verifyEqual(returned, expected)
   testCase.verifyNotEmpty(testCase.TestData.report.function_dependencies)
end

function test_selfContained(testCase)
   % Every file the core chain requires resolves inside the toolbox or is
   % shadowed by a same-named vendored copy: the core chain is
   % self-contained.
   returned = testCase.TestData.report.missing_dependencies;
   expected = testCase.TestData.installedmessage;
   testCase.verifyEqual(returned, expected)
end

function test_productsDeclared(testCase)
   % Every detected product, except the known requiredFilesAndProducts
   % false positives, is declared on the DESCRIPTION MatlabProducts line.
   returned = testCase.TestData.report.undeclared_products;
   expected = 'all products are declared';
   testCase.verifyEqual(returned, expected)
end

function test_optionShapes(testCase)
   % The all, report, and installed options return their documented
   % shapes for a single small function.
   smallfunction = testCase.TestData.smallfunction;

   % The all option returns a table with one function_dependencies column.
   alltable_returned = baseflow.internal.dependencies(smallfunction, 'all');
   varnames_expected = {'function_dependencies'};
   testCase.verifyClass(alltable_returned, 'table')
   testCase.verifyEqual(alltable_returned.Properties.VariableNames, ...
      varnames_expected)

   % The report option returns the function and product lists only.
   report_returned = baseflow.internal.dependencies(smallfunction, 'report');
   fields_expected = sort({'function_dependencies'; 'product_dependencies'});
   testCase.verifyEqual(sort(fieldnames(report_returned)), fields_expected)

   % The installed option adds one logical flag per product.
   inventory_returned = baseflow.internal.dependencies(smallfunction, ...
      'installed');
   count_expected = numel(inventory_returned.product_dependencies);
   testCase.verifyClass(inventory_returned.installed, 'logical')
   testCase.verifyNumElements(inventory_returned.installed, count_expected)
end

function test_unknownFunctionErrors(testCase)
   % An unresolvable function name raises the documented error.
   expected = 'baseflow:dependencies:unknownFunction';
   testCase.verifyError(@() baseflow.internal.dependencies( ...
      'nosuchfunction_xyz', 'report'), expected)
end

function test_pathRestored(testCase)
   % The analysis puts toolbox paths first and must restore the caller path.
   expected = path();
   baseflow.internal.dependencies(testCase.TestData.smallfunction, 'report');
   returned = path();
   testCase.verifyEqual(returned, expected)
end

function test_resolveWithNothingMissing(testCase)
   % resolve with no missing files reports success and copies nothing.
   report = baseflow.internal.dependencies( ...
      testCase.TestData.smallfunction, 'resolve');
   returned = report.missing_dependencies;
   expected = testCase.TestData.installedmessage;
   testCase.verifyEqual(returned, expected)
end

function test_resolveCopiesMissingFunctions(testCase)
   % resolve copies every missing .m file into +baseflow/private and puts
   % nothing in data. The caller and its callee sit outside the toolbox,
   % so the analysis classifies both as missing.
   callername = 'depresolvecaller';
   calleename = 'depresolvecallee';

   % Write the analysis files before the path change, so the path
   % fixture sees them without a rehash.
   temp = buildtemptoolbox(testCase);
   writefunction(temp.analysis, callername, sprintf('   %s();', calleename));
   writefunction(temp.analysis, calleename, '   disp(pi);');
   shadowtoolbox(testCase, temp);
   report = baseflow.internal.dependencies(callername, 'resolve');

   % The report lists both functions as missing.
   missing_returned = sortedbasenames(report.missing_dependencies);
   missing_expected = sort({[callername, '.m']; [calleename, '.m']});
   testCase.verifyEqual(missing_returned, missing_expected)

   % Both functions land in the vendored private folder, and the data
   % folder stays empty.
   private_returned = folderfilenames(temp.private);
   private_expected = missing_expected;
   testCase.verifyEqual(private_returned, private_expected)
   data_returned = folderfilenames(temp.data);
   data_expected = cell(0, 1);
   testCase.verifyEqual(data_returned, data_expected)
   verifyrepositoryuntouched(testCase, missing_expected)
end

function test_resolveCopiesMissingDataFiles(testCase)
   % resolve copies a missing data file into toolbox/data, not into
   % +baseflow/private. requiredFilesAndProducts reports a .mat file that a
   % function loads by a literal file name, so the analysis of that
   % function reaches the data copy loop.
   loadername = 'depresolveloader';
   dataname = 'depresolvedata.mat';
   loaderbody = sprintf('   data = load(''%s'');\n   disp(data);', dataname);
   datavalue = 1;

   % Write the analysis files before the path change, so the path
   % fixture sees them without a rehash.
   temp = buildtemptoolbox(testCase);
   writefunction(temp.analysis, loadername, loaderbody);
   save(fullfile(temp.analysis, dataname), 'datavalue');
   shadowtoolbox(testCase, temp);
   report = baseflow.internal.dependencies(loadername, 'resolve');

   % The report lists the loader function and its data file as missing.
   missing_returned = sortedbasenames(report.missing_dependencies);
   missing_expected = sort({[loadername, '.m']; dataname});
   testCase.verifyEqual(missing_returned, missing_expected)

   % The data file lands in toolbox/data and the loader function lands in
   % the vendored private folder.
   data_returned = folderfilenames(temp.data);
   data_expected = {dataname};
   testCase.verifyEqual(data_returned, data_expected)
   private_returned = folderfilenames(temp.private);
   private_expected = {[loadername, '.m']};
   testCase.verifyEqual(private_returned, private_expected)
   verifyrepositoryuntouched(testCase, missing_expected)
end

function test_plfitbClassification(testCase)
   % plfitb's r_plfit dependency stays external by decision, so the check
   % lists it as known external on every machine.
   report = baseflow.internal.dependencies('baseflow.plfitb', 'check');
   returned = sortedbasenames(report.known_external);
   expected = {'r_plfit.m'};
   testCase.verifyEqual(returned, expected)
end

function test_loadflowParkedReader(testCase)
   % loadflow's parked readflow reaches matfunclib files only through dead
   % code, so the check reports no missing dependency for loadflow.
   report = baseflow.internal.dependencies('baseflow.loadflow', 'check');
   returned = report.missing_dependencies;
   expected = 'all dependencies are installed';
   testCase.verifyEqual(returned, expected)
end

function test_setupDependencies(testCase)
   % Setup('dependencies') runs the whole-API live check headless, returns
   % the report fields, and records the dependencies_checked preference
   % with the value the check produced.
   prefgroup = 'baseflow';
   prefname = 'dependencies_checked';
   fields_expected = {'missing_dependencies', 'product_dependencies', ...
      'undeclared_products'};

   % Restore any existing preference value after the check overwrites it.
   if ispref(prefgroup, prefname)
      prior = getpref(prefgroup, prefname);
      testCase.addTeardown(@() setpref(prefgroup, prefname, prior));
   end
   [~, msg_returned] = evalc('Setup(''dependencies'')');
   testCase.verifyTrue(msg_returned.dependencies)
   testCase.verifyTrue(all(ismember(fields_expected, ...
      fieldnames(msg_returned))))

   % No entry point awaits a decision, so msg has no pending_decision field.
   testCase.verifyFalse(isfield(msg_returned, 'pending_decision'))

   % The preference records the result of the check, not only its existence.
   pref_expected = ischar(msg_returned.missing_dependencies) && ...
      strcmp(msg_returned.missing_dependencies, ...
      testCase.TestData.installedmessage);
   testCase.verifyEqual(getpref(prefgroup, prefname), pref_expected)
end

%% Local helpers
function temp = buildtemptoolbox(testCase)
   %BUILDTEMPTOOLBOX Build a temporary toolbox tree for the resolve tests.
   %
   %  temp = buildtemptoolbox(testCase) copies dependencies.m and its
   %  toolboxpath helper into a temporary toolbox tree with empty
   %  +baseflow/private and data folders. It also creates an empty
   %  analysis folder beside the tree. temp is the toolboxlayout struct of
   %  the tree plus the analysis folder and the runner file path of the
   %  copied dependencies.m. The fixture deletes the tree in teardown.
   import matlab.unittest.fixtures.TemporaryFolderFixture
   runnerfile = 'dependencies.m';
   helperfile = 'toolboxpath.m';

   % The repository toolbox supplies the files under test. The resolve
   % option with named functions calls only the toolboxpath private helper.
   repo = toolboxlayout(fullfile(repositoryroot(), 'toolbox'));

   % Create the temporary tree with the two empty copy targets. The
   % analysis folder sits outside the tree, so every analyzed file is
   % outside the toolbox that the temporary dependencies.m sees.
   tempfolder = testCase.applyFixture(TemporaryFolderFixture);
   temp = toolboxlayout(fullfile(tempfolder.Folder, 'toolbox'));
   temp.analysis = fullfile(tempfolder.Folder, 'analysis');
   mkdir(temp.internalprivate);
   mkdir(temp.private);
   mkdir(temp.data);
   mkdir(temp.analysis);
   copyfile(fullfile(repo.internal, runnerfile), temp.internal);
   copyfile(fullfile(repo.internalprivate, helperfile), ...
      temp.internalprivate);
   temp.runner = fullfile(temp.internal, runnerfile);
end

function shadowtoolbox(testCase, temp)
   %SHADOWTOOLBOX Put the temporary toolbox first on the path.
   %
   %  shadowtoolbox(testCase, temp) adds the analysis folder and then the
   %  temporary toolbox root to the front of the path. The resolve option
   %  copies into the toolbox that holds the running dependencies.m, so
   %  the shadow copy keeps every write out of the repository toolbox
   %  folder. The fixtures restore the path in teardown.
   import matlab.unittest.fixtures.PathFixture
   testCase.applyFixture(PathFixture(temp.analysis));
   testCase.applyFixture(PathFixture(temp.root));

   % Stop the test when the shadow copy does not run: a resolve call
   % through the repository copy would write into the repository toolbox.
   runner_returned = which('baseflow.internal.dependencies');
   runner_expected = temp.runner;
   testCase.assertEqual(runner_returned, runner_expected, ...
      'the temporary dependencies.m does not shadow the repository copy')
end

function layout = toolboxlayout(root)
   %TOOLBOXLAYOUT Return the folders of a toolbox tree as a struct.
   %
   %  layout = toolboxlayout(root) returns the root, +internal, +internal
   %  private, +baseflow private, and data folder paths. The resolve tests
   %  use one layout for the repository toolbox and one for the temporary
   %  toolbox.
   layout.root = root;
   layout.internal = fullfile(root, '+baseflow', '+internal');
   layout.internalprivate = fullfile(layout.internal, 'private');
   layout.private = fullfile(root, '+baseflow', 'private');
   layout.data = fullfile(root, 'data');
end

function root = repositoryroot()
   %REPOSITORYROOT Return the repository root, the parent of tests/.
   root = fileparts(fileparts(mfilename('fullpath')));
end

function writefunction(folder, name, body)
   %WRITEFUNCTION Write a one-function .m file for the dependency analysis.
   %
   %  writefunction(folder, name, body) writes <folder>/<name>.m with a
   %  function header, the body text, and an explicit end.
   fid = fopen(fullfile(folder, [name, '.m']), 'w');
   closefile = onCleanup(@() fclose(fid));
   fprintf(fid, 'function %s()\n%s\nend\n', name, body);
end

function names = sortedbasenames(files)
   %SORTEDBASENAMES Return sorted file names with extensions as a column.
   %
   %  The analysis returns full paths whose temporary prefix differs by
   %  machine, so the tests compare file names only.
   [~, base, ext] = cellfun(@fileparts, files(:), 'UniformOutput', false);
   names = sort(strcat(base, ext));
end

function names = folderfilenames(folder)
   %FOLDERFILENAMES Return the sorted names of the files in one folder.
   %
   %  The list excludes subfolders and the . and .. entries. The reshape makes
   %  an empty folder return a 0-by-1 cell, the shape of a file list.
   listing = dir(folder);
   names = sort(reshape({listing(~[listing.isdir]).name}, [], 1));
end

function verifyrepositoryuntouched(testCase, names)
   %VERIFYREPOSITORYUNTOUCHED Verify no resolved file reached the repository.
   %
   %  The resolve tests copy only into the temporary toolbox. None of the
   %  resolved file names may exist in the repository +baseflow private or
   %  data folders.
   repo = toolboxlayout(fullfile(repositoryroot(), 'toolbox'));
   [folders, files] = ndgrid({repo.private; repo.data}, names);
   found = cellfun(@(d, f) isfile(fullfile(d, f)), folders(:), files(:));
   testCase.verifyFalse(any(found))
end
