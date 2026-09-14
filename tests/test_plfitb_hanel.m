function tests = test_plfitb_hanel
   %TEST_PLFITB_HANEL Test the r_plfit arguments plfitb's 'hanel' passes.
   %
   % A stub r_plfit on a temporary path folder shadows any real copy and
   % records the arguments. The test checks that the call includes 'cdat'
   % (continuous data). Without it, r_plfit integer-bins the real-valued
   % tau sample. The test also checks for the search-bound names 'exp_min'
   % and 'exp_max', which the r_plfit parser accepts. The r_plfit help names
   % them 'alpha_*', but the parser skips unknown options without an error.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   import matlab.unittest.fixtures.TemporaryFolderFixture
   import matlab.unittest.fixtures.PathFixture

   % The stub writes its arguments to this appdata key and returns this
   % fixed alpha. The test reads the same key and expects the same alpha.
   appdatakey = 'r_plfit_stub_args';
   alpha_expected = 2.5;
   testCase.TestData.appdatakey = appdatakey;
   testCase.TestData.alpha_expected = alpha_expected;

   % Write the stub: it records varargin and returns fixed outputs in
   % the edited-copy signature plfitb expects. fopen returns -1 when it
   % cannot open the file.
   stubdir = testCase.applyFixture(TemporaryFolderFixture);
   fid = fopen(fullfile(stubdir.Folder, 'r_plfit.m'), 'w');
   testCase.assertGreaterThan(fid, 0)
   fprintf(fid, '%s\n', ...
      'function [alpha, xmin, L, D, out] = r_plfit(x, varargin)', ...
      '   %R_PLFIT Test stub: records the call arguments in appdata.', ...
      sprintf('   setappdata(0, ''%s'', varargin);', appdatakey), ...
      sprintf('   alpha = %g;', alpha_expected), ...
      '   xmin = min(x);', ...
      '   L = nan;', ...
      '   D = nan;', ...
      '   out = struct();', ...
      'end');
   fclose(fid);
   testCase.applyFixture(PathFixture(stubdir.Folder));
   testCase.addTeardown(@() rmappdata(0, appdatakey));
end

function test_hanelPassesCdatAndExpBounds(testCase)
   import matlab.unittest.constraints.IsSubsetOf

   % Build a deterministic Pareto-like sample by inverse CDF at 2000 midpoint
   % quantiles. A pdf exponent p gives the CDF exponent p - 1.
   pdfexponent = 2.5;
   u = ((1:2000)' - 0.5)/2000;
   x = (1 - u).^(-1/(pdfexponent - 1));
   returned = baseflow.plfitb(x, 'method', 'hanel');

   % The stub's alpha passes through plfitb's conversions unchanged.
   testCase.verifyEqual(returned.alpha, testCase.TestData.alpha_expected)

   % The recorded arguments carry the continuous-data flag and the
   % search-bound names the parser accepts.
   args_returned = getappdata(0, testCase.TestData.appdatakey);
   testCase.assertNotEmpty(args_returned)
   flags_returned = args_returned(cellfun(@ischar, args_returned));
   flags_expected = {'cdat', 'exp_min', 'exp_max'};
   testCase.verifyThat(flags_expected, IsSubsetOf(flags_returned))
end
