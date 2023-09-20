function tests = test_internal
   %TEST_INTERNAL Test the toolbox internal functions.
   tests = functiontests(localfunctions);
end

function setup(testCase) %#ok<INUSD>

end

function teardown(testCase) %#ok<INUSD>

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
   [parentpath, foldername] = fileparts(demofilepath);
   
   testCase.verifyEqual(parentpath, baseflow.internal.basepath(), ...
      'Expected buildpath() to return toolbox/demos folder.');
   
   testCase.verifyEqual(foldername, 'demos', ...
      'Expected buildpath() to return toolbox/demos folder.');
end

function test_docpath(testCase)
   docfilename = baseflow.internal.docpath('baseflow_gettingStarted');
   [foldername, filename, fileext] = fileparts(docfilename);
   
   testCase.verifyEqual(foldername, baseflow.internal.basepath('docs/html'), ...
      'Expected docpath() to return toolbox/docs/html folder.');
   
   testCase.verifyEqual(filename, 'baseflow_gettingStarted', ...
      'Expected docpath() to return baseflow_gettingStarted.html file.');
   
   testCase.verifyEqual(fileext, '.html', ...
      'Expected docpath() to return a .html file.');
end

function test_version(testCase)
   version = baseflow.internal.version();
   testCase.verifyTrue(ischar(version))
end
