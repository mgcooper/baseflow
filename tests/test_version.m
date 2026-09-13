classdef test_version < matlab.unittest.TestCase
   %TEST_VERSION Assert the version metadata locations agree.
   %
   % Sources: baseflow.internal.version, DESCRIPTION, CITATION.cff,
   % .zenodo.json (the version field and the release tree URL), and the
   % toolbox/info.xml version comment. The 1.0.0 release shipped with
   % runtime 0.1.0 metadata. The test fails when any of these sources
   % disagrees with the runtime version.

   properties (TestParameter)
      % Each version source: the file relative to the project root and the
      % pattern that captures its declared version.
      source = struct( ...
         'description', {{'DESCRIPTION', 'Version:\s*(\d+\.\d+\.\d+)'}}, ...
         'citation', {{'CITATION.cff', '^version:\s*(\d+\.\d+\.\d+)'}}, ...
         'zenodo', {{'.zenodo.json', '"version":\s*"v(\d+\.\d+\.\d+)"'}}, ...
         'zenodotree', {{'.zenodo.json', 'tree/v(\d+\.\d+\.\d+)'}}, ...
         'infoxml', {{fullfile('toolbox', 'info.xml'), ...
         'Version (\d+\.\d+\.\d+)'}})
   end

   methods (Test)
      function test_versionsAgree(testCase, source)
         % Every declared version equals the runtime version.
         projectroot = fileparts(fileparts(mfilename('fullpath')));
         txt = fileread(fullfile(projectroot, source{1}));
         returned = getversion(txt, source{2});
         expected = baseflow.internal.version('silent');
         testCase.verifyEqual(returned, expected, sprintf( ...
            'version source %s disagrees with baseflow.internal.version', ...
            source{1}))
      end
   end
end

function ver = getversion(txt, pattern)
   % GETVERSION Extract one semantic version with the given pattern.
   tok = regexp(txt, pattern, 'tokens', 'once', 'lineanchors');
   assert(~isempty(tok), 'version pattern not found: %s', pattern)
   ver = tok{1};
end
