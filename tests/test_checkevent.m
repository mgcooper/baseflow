classdef test_checkevent < matlab.unittest.TestCase
   %TEST_CHECKEVENT Test the baseflow.checkevent event plot.
   %
   % The suite checks that checkevent opens one figure and no extra empty
   % figure, that it rejects an axes input, and that each fitted-curve
   % legend uses the label helper for the plotted curve. Each test plots
   % one synthetic recession event with no rain.
   %
   % See also: baseflow.checkevent, baseflow.QtString, baseflow.aQbString

   properties (TestParameter)
      % The checkevent 'order' option. NaN fits b freely; a value also
      % draws the fixed-b fit, which adds a second label to each legend.
      order = struct('free_b', NaN, 'fixed_b', 2)
   end

   properties
      % The checkevent positional inputs for one synthetic event.
      T
      q
      dqdt
      rain
      tags
   end

   methods (TestClassSetup)
      function buildevent(testCase)
         % Build one synthetic recession event with no rain. Every sample
         % has event tag 1.
         [t, testCase.q, testCase.dqdt] = ...
            baseflow.generateTestData(1e-2, 1.5, 100);
         testCase.T = datetime(2000, 1, 1) + days(t(:));
         testCase.q = testCase.q(:);
         testCase.dqdt = testCase.dqdt(:);
         testCase.rain = zeros(size(testCase.q));
         testCase.tags = ones(size(testCase.q));
      end
   end

   methods (TestMethodSetup)
      function isolatefigures(testCase)
         % Close the figures each test opens. Clear the current figure so
         % a call to gca would open a new figure, which the figure count
         % test detects. The teardown restores the current figure.
         figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(figsbefore));
         currentfig = get(groot, 'CurrentFigure');
         testCase.addTeardown(@() restorecurrentfigure(currentfig));
         set(groot, 'CurrentFigure', [])
      end
   end

   methods (Test)
      function test_opensonefigure(testCase)
         % Verify that checkevent opens exactly one figure, the one it
         % returns in h.f, and no empty figure from a default axes.
         figsbefore = findall(0, 'Type', 'figure');

         h = baseflow.checkevent(testCase.T, testCase.q, testCase.q, ...
            testCase.dqdt, testCase.rain, testCase.tags, 1);

         figsafter = findall(0, 'Type', 'figure');
         returned = figsafter(~ismember(figsafter, figsbefore));
         expected = h.f;
         testCase.verifyEqual(returned, expected)
      end

      function test_allnanevent(testCase)
         % Verify that an event with no valid flow still draws the figure.
         % The fit is skipped, so every fitted output is nan.
         qnan = nan(size(testCase.q));

         h = baseflow.checkevent(testCase.T, testCase.q, qnan, ...
            testCase.dqdt, testCase.rain, testCase.tags, 1);

         testCase.verifyTrue(isgraphics(h.f))
      end

      function test_rejectsax(testCase)
         % Verify that checkevent takes no 'ax' option, because it always
         % opens its own four-panel figure.
         expected = 'MATLAB:InputParser:UnmatchedParameter';

         testCase.verifyError(@() baseflow.checkevent(testCase.T, ...
            testCase.q, testCase.q, testCase.dqdt, testCase.rain, ...
            testCase.tags, 1, 'ax', []), expected)
      end

      function test_legendlabels(testCase, order)
         % Verify that checkevent labels the fitted Q(t) curve with
         % QtString and the fitted -dQ/dt curve with aQbString. The call
         % also checks that the checkevent parser accepts both the Q and q
         % inputs.

         % Fit the event as checkevent does to get the expected labels
         Fit = baseflow.fitab(testCase.q, testCase.dqdt, 'nls');
         Qt_expected = {baseflow.QtString(Fit.ab, 'printvalues', true)};
         aQb_expected = {baseflow.aQbString(Fit.ab, 'printvalues', true)};
         if ~isnan(order)
            Fit = baseflow.fitab(testCase.q, testCase.dqdt, 'mean', ...
               'order', order);
            Qt_expected{2} = baseflow.QtString(Fit.ab, 'printvalues', true);
            aQb_expected{2} = baseflow.aQbString(Fit.ab, 'printvalues', true);
         end

         h = baseflow.checkevent(testCase.T, testCase.q, testCase.q, ...
            testCase.dqdt, testCase.rain, testCase.tags, 1, ...
            'order', order);

         % The Q legend starts with the data entry and ends with 'rain'.
         % The -dQ/dt legend starts with the data entry.
         Qt_returned = h.leg2.String(2:end-1);
         aQb_returned = h.leg3.String(2:end);

         testCase.verifyEqual(Qt_returned, Qt_expected)
         testCase.verifyEqual(aQb_returned, aQb_expected)
      end
   end
end

%% LOCAL FUNCTIONS
function restorecurrentfigure(fig)
   %RESTORECURRENTFIGURE Make FIG the current figure if it is still open.
   %
   % A test clears the current figure before it runs. A user figure that
   % was current before the test becomes current again. An empty fig or a
   % figure closed during the test leaves the current figure unchanged.
   if ~isempty(fig) && isvalid(fig)
      set(groot, 'CurrentFigure', fig)
   end
end
