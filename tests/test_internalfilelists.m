classdef test_internalfilelists < matlab.unittest.TestCase
   %TEST_INTERNALFILELISTS Test the listfiles and mpackagefolders helpers.
   %
   % Both helpers live in toolbox/+baseflow/+internal/private/, so the
   % tests run against setup-time copies on a temporary path folder (the
   % same pattern as test_withcd). The tests cover the positional folder
   % input, the name-value options the toolbox tooling uses, the
   % arguments-block conversion of numeric 0/1 to logical, and the error
   % for an unknown option.

   properties (TestParameter)
      % The listing scope and the sorted .m file names it returns. The
      % subfolders option adds the file in the +pkg folder.
      scope = struct( ...
         'topfolder', struct('subfolders', false, 'expected', "file1.m"), ...
         'subfolders', struct('subfolders', true, ...
         'expected', ["file1.m"; "pkgfun.m"]))

      % The value passed to the true options: a logical, and the numeric 1
      % that the arguments block converts to logical.
      truevalue = struct('logical', true, 'numeric', 1)
   end

   properties (Access = private)
      % Full path of the temporary folder that holds the test tree.
      target
   end

   methods (TestClassSetup)
      function setupTree(testCase)
         % Copy the helpers onto a temporary path folder and build a small
         % tree: target/file1.m, target/notes.txt, target/+pkg/pkgfun.m.
         import matlab.unittest.fixtures.TemporaryFolderFixture
         import matlab.unittest.fixtures.PathFixture

         thispath = fileparts(mfilename('fullpath'));
         srcdir = fullfile(fileparts(thispath), 'toolbox', '+baseflow', ...
            '+internal', 'private');
         pathfolder = testCase.applyFixture(TemporaryFolderFixture);
         copyfile(fullfile(srcdir, 'listfiles.m'), pathfolder.Folder);
         copyfile(fullfile(srcdir, 'mpackagefolders.m'), pathfolder.Folder);
         testCase.applyFixture(PathFixture(pathfolder.Folder));

         folder = testCase.applyFixture(TemporaryFolderFixture);
         testCase.target = folder.Folder;
         fclose(fopen(fullfile(testCase.target, 'file1.m'), 'w'));
         fclose(fopen(fullfile(testCase.target, 'notes.txt'), 'w'));
         mkdir(fullfile(testCase.target, '+pkg'));
         fclose(fopen(fullfile(testCase.target, '+pkg', 'pkgfun.m'), 'w'));
      end
   end

   methods (Test)
      function test_listfilesStructDefault(testCase)
         % The default returns a dir-style struct of the folder's files.
         returned = listfiles(testCase.target);
         testCase.verifyClass(returned, 'struct')
         expected = {'file1.m', 'notes.txt'};
         testCase.verifyEqual(sort({returned.name}), expected)
      end

      function test_listfilesMfilesAsList(testCase, scope, truevalue)
         % The mfiles filter with aslist and asstring returns only .m
         % names, for each listing scope and each form of the true value.
         returned = listfiles(testCase.target, ...
            'subfolders', scope.subfolders, 'aslist', truevalue, ...
            'asstring', truevalue, 'mfiles', truevalue);
         testCase.verifyEqual(sort(returned), scope.expected)
      end

      function test_mpackagefoldersPathlist(testCase)
         % The aspathlist and asstring options return the +pkg full path,
         % the same call signature makecontents uses.
         returned = mpackagefolders(testCase.target, ...
            'aspathlist', true, 'asstring', true);
         testCase.verifyClass(returned, 'string')
         testCase.verifyTrue(endsWith(returned, '+pkg'))
         expected = string(fullfile(testCase.target, '+pkg'));
         testCase.verifyEqual(returned, expected)
      end

      function test_invalidOptionErrors(testCase)
         % An unknown name-value option raises the arguments-block error,
         % which MATLAB reports as too many inputs.
         expected = 'MATLAB:TooManyInputs';
         testCase.verifyError(@() listfiles(testCase.target, ...
            'nosuchoption', true), expected)
      end
   end
end
