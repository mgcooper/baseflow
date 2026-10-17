classdef test_makedocs < matlab.unittest.TestCase
   %TEST_MAKEDOCS Test that the docs build keeps machine metadata local.
   %
   % The 'docsearch' option of baseflow.internal.makedocs calls
   % builddocsearchdb. It writes toolbox/docs/html/custom_toolbox.json with
   % the absolute path of the folder it builds in, then indexes the pages.
   % Each build writes the file again, and a copy names a folder that
   % exists only on the machine that built it. So version control and the
   % toolbox package must leave it out, and the package must keep the
   % search database.

   properties (Constant)
      % The generated file, relative to the project root. Git takes the
      % forward slashes on every platform.
      metadatafile = 'toolbox/docs/html/custom_toolbox.json'

      % The search database folder, relative to the project root. The
      % package must keep every file in it.
      searchdb = 'toolbox/docs/html/helpsearch-v4_en'

      % Any identifier works, because the test builds no package.
      packageid = 'baseflow-test'
   end

   properties
      % The project root, the folder that holds tests/ and toolbox/.
      Root
   end

   methods (TestClassSetup)
      function seedmetadata(testCase)
         % A clean checkout holds no generated file, so a package check
         % would pass whether or not the rule works. Write a placeholder
         % when the file is missing, and delete only that copy.
         testCase.Root = fileparts(fileparts(mfilename('fullpath')));
         seeded = fullfile(testCase.Root, testCase.metadatafile);
         if ~isfile(seeded)
            writelines("{}", seeded);
            testCase.addTeardown(@delete, seeded);
         end
      end
   end

   methods (Test)
      function test_packageOmitsSearchMetadata(testCase)
         % The Package Toolbox task reads toolbox/toolbox.ignore. It leaves
         % out the generated file and keeps the search database.
         testCase.assumeTrue( ...
            exist('matlab.addons.toolbox.ToolboxOptions', 'class') == 8, ...
            'ToolboxOptions needs MATLAB R2023a or later')
         opts = matlab.addons.toolbox.ToolboxOptions( ...
            fullfile(testCase.Root, 'toolbox'), testCase.packageid);
         packaged = string(opts.ToolboxFiles);

         % The files of the search database on disk are the files the
         % package must hold.
         ondisk = dir(fullfile(testCase.Root, testCase.searchdb, '**', '*'));
         ondisk = ondisk(~[ondisk.isdir]);
         searchdb_expected = sort(string(fullfile({ondisk.folder}, ...
            {ondisk.name})));
         searchdb_returned = sort(packaged(startsWith(packaged, ...
            fullfile(testCase.Root, testCase.searchdb))));
         metadata_returned = packaged(endsWith(packaged, ...
            "custom_toolbox.json"));

         testCase.verifyEmpty(metadata_returned)
         testCase.verifyNotEmpty(searchdb_expected)
         testCase.verifyEqual(searchdb_returned(:), searchdb_expected(:))
      end

      function test_versionControlIgnoresSearchMetadata(testCase)
         % Git reports a tracked file as not ignored, so this check fails
         % when the file is tracked again or the ignore rule is lost. Then a
         % docs build changes the worktree. Run Git from the project root,
         % so the commands hold no path that the shell could expand.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.CurrentFolderFixture(testCase.Root));
         [status, ~] = system('git rev-parse --git-dir');
         testCase.assumeEqual(status, 0, ...
            'the project root is not a Git checkout')

         [returned, ~] = system(['git check-ignore -q -- ' ...
            testCase.metadatafile]);
         expected = 0;

         testCase.verifyEqual(returned, expected)
      end
   end
end
