function tests = test_withcd
   %TEST_WITHCD Test the withcd temporary-directory helper.
   %
   % withcd lives in toolbox/+baseflow/+internal/private/, so no test can
   % reach it through the package path: MATLAB exposes a private function
   % only to functions in its parent folder. Setup copies the source file
   % onto a temporary folder placed on the path, and the tests run against
   % that copy. The cd target is a second temporary folder so no test
   % writes inside the repository.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Copy withcd.m onto the path and create the resolved cd target.
   import matlab.unittest.fixtures.TemporaryFolderFixture
   import matlab.unittest.fixtures.PathFixture

   % Copy withcd.m from +internal/private onto a temporary path folder.
   thispath = fileparts(mfilename('fullpath'));
   srcfile = fullfile(fileparts(thispath), 'toolbox', '+baseflow', ...
      '+internal', 'private', 'withcd.m');
   pathfolder = testCase.applyFixture(TemporaryFolderFixture);
   copyfile(srcfile, pathfolder.Folder);
   testCase.applyFixture(PathFixture(pathfolder.Folder));

   % Create the cd target and resolve it the way pwd() reports it, so the
   % comparisons survive the macOS /var -> /private/var symlink.
   targetfixture = testCase.applyFixture(TemporaryFolderFixture);
   startdir = pwd();
   cd(targetfixture.Folder);
   testCase.TestData.target = pwd();
   cd(startdir);
end

function test_cdAndRestore(testCase)
   % withcd changes to the target for the cleanup object's lifetime and
   % restores the original directory when the object is destroyed.
   originalDir = pwd();
   cleanup_returned = withcd(testCase.TestData.target);
   testCase.verifyClass(cleanup_returned, 'onCleanup')
   returned = pwd();
   expected = testCase.TestData.target;
   testCase.verifyEqual(returned, expected, ...
      'withcd failed to change to the target directory')
   clear cleanup_returned
   returned = pwd();
   expected = originalDir;
   testCase.verifyEqual(returned, expected, ...
      'withcd failed to restore the original directory')
end

function test_notAFolderErrors(testCase)
   % A path that is not an existing folder raises the mustBeFolder
   % validator error from the arguments block.
   testCase.verifyError(@() withcd(fullfile(testCase.TestData.target, ...
      'no-such-subfolder')), 'MATLAB:validators:mustBeFolder')
end

function test_fileCreatedInTarget(testCase)
   % Implements the parked assertion from the original test file: a file
   % created inside the withcd context lands in the target directory. The
   % parked version shelled out with '!touch test.txt' against the repo
   % root; this version uses fopen, which works on every platform, and
   % writes to the temporary target instead.
   target = testCase.TestData.target;
   cleanup_returned = withcd(target);
   testCase.verifyClass(cleanup_returned, 'onCleanup')
   % fopen returns -1 when it cannot open the file.
   fid = fopen('test.txt', 'w');
   testCase.assertGreaterThan(fid, 0, 'failed to open test.txt for writing')
   fclose(fid);
   returned = isfile(fullfile(target, 'test.txt'));
   testCase.verifyTrue(returned, ...
      'file created under withcd did not land in the target directory')
   clear cleanup_returned
end
