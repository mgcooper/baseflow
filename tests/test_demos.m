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
