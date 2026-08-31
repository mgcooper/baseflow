function tests = test_demos
   %TEST_DEMOS Run every demo script in toolbox/demos/mfiles headless.
   %
   % Each demo runs through the rundemo local function by absolute path.
   % run() cds into the demo folder for the duration of the script, so no
   % explicit cd is needed. The isolated rundemo workspace absorbs the
   % 'clearvars' each demo issues, so the loop state in the test function
   % survives.
   %
   % Note: the demos also issue 'close all'. setupOnce hides pre-existing
   % figure handles so that call cannot close them; TODO.md records the
   % deferred edit to the generated demo mfiles themselves.
   tests = functiontests(localfunctions);
end

function setupOnce(testCase)
   % Snapshot open figures and hide their handles. The demos issue a plain
   % 'close all', which skips figures whose HandleVisibility is 'off', so
   % figures open before the run survive. teardownOnce restores the saved
   % visibility values.
   figs = findall(0, 'Type', 'figure');
   testCase.TestData.figsbefore = figs;
   testCase.TestData.visibility = get(figs, {'HandleVisibility'});
   set(figs, 'HandleVisibility', 'off')
end

function teardownOnce(testCase)
   % Close the figures the demos created (see tests/closenewfigs.m), then
   % restore the hidden handles on the surviving snapshot figures.
   closenewfigs(testCase.TestData.figsbefore)
   figs = testCase.TestData.figsbefore;
   for k = 1:numel(figs)
      if isvalid(figs(k))
         set(figs(k), 'HandleVisibility', testCase.TestData.visibility{k})
      end
   end
end

function test_rundemos(testCase)
   % Every demo script must run to completion headless.
   demodir = baseflow.internal.buildpath('demos', 'mfiles');
   demofiles = dir(fullfile(demodir, '*.m'));
   testCase.assertNotEmpty(demofiles, 'no demo scripts found')

   % The theory demos call syms, so they need the Symbolic Math Toolbox.
   % Skip any demo whose source uses syms when syms does not resolve, so
   % the result reflects the demos the machine can run. Note: probe with
   % exist, not license('test','Symbolic_Toolbox') - CI batch licensing
   % reports the license as available even when the product is not
   % installed (run 33347197058).
   if exist('syms', 'file') == 0
      needsyms = arrayfun(@(d) contains( ...
         fileread(fullfile(demodir, d.name)), 'syms'), demofiles);
      for k = find(needsyms(:)')
         fprintf('skipping %s: no Symbolic Math Toolbox license\n', ...
            demofiles(k).name)
      end
      demofiles = demofiles(~needsyms);
   end

   for k = 1:numel(demofiles)
      [returned, errmsg] = rundemo(fullfile(demodir, demofiles(k).name));
      expected = true;
      testCase.verifyEqual(returned, expected, sprintf( ...
         'demo %s failed: %s', demofiles(k).name, errmsg))
   end
end

function [success, errmsg] = rundemo(demofile)
   % Isolated workspace: 'clearvars' inside the demo clears only this
   % function's locals, never the calling test's loop state. Both outputs
   % are assigned after run() returns, because the demo's 'clearvars'
   % would clear any value assigned before it.
   try
      run(demofile)
      success = true;
      errmsg = '';
   catch cause
      success = false;
      errmsg = cause.message;
   end
end
