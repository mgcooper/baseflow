function tests = test_internal
   %TEST_INTERNAL Test the toolbox internal functions.
   tests = functiontests(localfunctions);
end

function setup(testCase) %#ok<INUSD>

end

function teardown(testCase) %#ok<INUSD>

end

function test_versionBannerCarriesTheVersion(testCase)
   % The verbose banner draws the version in two slots built from the
   % version string, the major number beside the v and the minor and patch
   % digits below it, so the art cannot fall behind a release.
   v = baseflow.internal.version('silent');
   number = sscanf(v, '%d.%d.%d');
   majorslot_expected = sprintf('|.  v%d', number(1));
   minorslot_expected = sprintf('|:  %d%d', number(2), number(3));

   returned = evalc('baseflow.internal.version()');

   testCase.verifySubstring(returned, majorslot_expected)
   testCase.verifySubstring(returned, minorslot_expected)
end

function test_basepath(testCase)
   toolboxpath = baseflow.internal.basepath();
   [~, toolboxfolder] = fileparts(toolboxpath);

   testCase.verifyTrue(isfolder(toolboxpath), ...
      'Expected toolbox/ folder to exist.');

   testCase.verifyTrue(strcmp('toolbox', toolboxfolder), ...
      'Expected toolbox/ folder to exist.');
end

function test_functionSignatures(testCase)
   % Validate the JSON and get the table
   T = validateFunctionSignaturesJSON(fullfile( ...
      baseflow.internal.basepath(), 'functionSignatures.json'));

   % Check if the table is empty
   testCase.verifyEmpty(T, ...
      'The functionSignatures.json file contains invalid entries.');
end

function test_buildpath(testCase)
   demofilepath = baseflow.internal.buildpath('demos');
   [parentpath_returned, foldername_returned] = fileparts(demofilepath);

   testCase.verifyEqual(parentpath_returned, baseflow.internal.basepath(), ...
      'Expected buildpath() to return toolbox/demos folder.');

   testCase.verifyEqual(foldername_returned, 'demos', ...
      'Expected buildpath() to return toolbox/demos folder.');
end

function test_docpath(testCase)
   docfilename = baseflow.internal.docpath('baseflow_gettingStarted');
   [foldername_returned, filename_returned, fileext_returned] = ...
      fileparts(docfilename);

   testCase.verifyEqual(foldername_returned, ...
      baseflow.internal.basepath('docs/html'), ...
      'Expected docpath() to return toolbox/docs/html folder.');

   testCase.verifyEqual(filename_returned, 'baseflow_gettingStarted', ...
      'Expected docpath() to return baseflow_gettingStarted.html file.');

   testCase.verifyEqual(fileext_returned, '.html', ...
      'Expected docpath() to return a .html file.');
end

function test_internalversion(testCase)
   % Note: the name test_version belongs to tests/test_version.m. A local
   % test with that name makes functiontests error, and the suite builder
   % then drops this whole file. Name the result returned, not version, so
   % it does not shadow the MATLAB version function.
   returned = baseflow.internal.version();
   testCase.verifyTrue(ischar(returned))
end

function test_vendoredm2html(testCase)
   % makedocs builds the function pages with the m2html copy in
   % tools/m2html. Check the entry point, the template class, and the
   % baseflow template that makedocs names.
   m2htmlfolder = fullfile(fileparts(baseflow.internal.basepath()), ...
      'tools', 'm2html');
   vendoredfiles = {
      'm2html.m'
      fullfile('@template', 'template.m')
      fullfile('templates', 'blue2_baseflow', 'master.tpl')
      };

   for n = 1:numel(vendoredfiles)
      testCase.verifyTrue( ...
         isfile(fullfile(m2htmlfolder, vendoredfiles{n})), ...
         ['Expected tools/m2html/' vendoredfiles{n} ' to exist.']);
   end
end
