classdef test_demos < matlab.unittest.TestCase
   %TEST_DEMOS Run every demo script in toolbox/demos/mfiles headless.
   %
   % Each demo runs through the rundemo local function by absolute path.
   % run() cds into the demo folder for the duration of the script, so no
   % explicit cd is needed. The isolated rundemo workspace absorbs the
   % 'clearvars' each demo issues, so the variables in the test method
   % survive.
   %
   % Note: hidefigures hides the handles of figures that were open before
   % the run, and the teardown deletes only the figures the demos open (see
   % tests/closenewfigs.m).

   properties (TestParameter)
      % One test row per demo script. listdemos fills this list.
      demofile
   end

   properties (Access = private)
      % Figures open before the run and their saved HandleVisibility values.
      figsbefore
      visibility
   end

   methods (TestParameterDefinition, Static)
      function demofile = listdemos()
         %LISTDEMOS List the runnable demo scripts, one field per demo.
         %
         % The suite builder drops this whole file with only a warning when
         % this method errors or returns no rows. The method therefore finds
         % the demo folder relative to this file, which needs no toolbox
         % path. When it finds no demos, it returns a 'none' row with an
         % empty path. test_rundemos fails on that row.
         demodir = fullfile(fileparts(fileparts(mfilename('fullpath'))), ...
            'toolbox', 'demos', 'mfiles');
         demofiles = dir(fullfile(demodir, '*.m'));

         % The theory demos call syms, so they need the Symbolic Math
         % Toolbox. Skip any demo whose source uses syms when syms does not
         % resolve, so the result reflects the demos the machine can run.
         % Note: probe with exist, not license('test','Symbolic_Toolbox').
         % CI batch licensing reports the license as available even when
         % the product is not installed (run 33347197058).
         if exist('syms', 'file') == 0
            needsyms = arrayfun(@(d) contains( ...
               fileread(fullfile(demodir, d.name)), 'syms'), demofiles);
            for k = find(needsyms(:)')
               fprintf(['skipping %s: Symbolic Math Toolbox not ' ...
                  'available\n'], demofiles(k).name)
            end
            demofiles = demofiles(~needsyms);
         end

         % Name each row after its demo. makeValidName keeps an unusual
         % file name from erroring, which would drop the whole file.
         demofile = struct();
         for k = 1:numel(demofiles)
            [~, demoname] = fileparts(demofiles(k).name);
            demofile.(matlab.lang.makeValidName(demoname)) = ...
               fullfile(demodir, demofiles(k).name);
         end
         if isempty(fieldnames(demofile))
            demofile = struct('none', '');
         end
      end
   end

   methods (TestClassSetup)
      function hidefigures(testCase)
         % Snapshot open figures and hide their handles, so demo code that
         % draws into or closes the current figure cannot change figures
         % that were open before the run. restorefigures restores the saved
         % visibility values.
         figs = findall(0, 'Type', 'figure');
         testCase.figsbefore = figs;
         testCase.visibility = get(figs, {'HandleVisibility'});
         set(figs, 'HandleVisibility', 'off')

         % A nonlinear fit that stops at the iteration limit warns. Several
         % demos reach that limit on the example record, so the warning is
         % expected output here rather than a problem to print. A user
         % running the demo still sees it.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'stats:nlinfit:IterationLimitExceeded'));
      end
   end

   methods (TestClassTeardown)
      function restorefigures(testCase)
         % Close the figures the demos created (see tests/closenewfigs.m),
         % then restore the hidden handles on the surviving snapshot figures.
         closenewfigs(testCase.figsbefore)
         figs = testCase.figsbefore;
         for k = 1:numel(figs)
            if isvalid(figs(k))
               set(figs(k), 'HandleVisibility', testCase.visibility{k})
            end
         end
      end
   end

   methods (Test)
      function test_rundemos(testCase, demofile)
         % Every demo script must run to completion headless.
         testCase.assertNotEmpty(demofile, 'no demo scripts found')

         [returned, errmsg] = rundemo(demofile);
         expected = true;
         testCase.verifyEqual(returned, expected, sprintf( ...
            'demo %s failed: %s', demofile, errmsg))
      end
   end
end

function [success, errmsg] = rundemo(demofile)
   % Isolated workspace: 'clearvars' inside the demo clears only this
   % function's locals, never the calling test's variables. Both outputs
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
