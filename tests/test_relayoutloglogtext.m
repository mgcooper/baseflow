classdef test_relayoutloglogtext < matlab.unittest.TestCase
   %TEST_RELAYOUTLOGLOGTEXT Test the angle reset of a rotated log-log label.
   %
   % relayoutloglogtext is private, so the tests reach it with
   % baseflow.privatefunction. The angle of a line on a log-log plot follows
   % the axis limits, so a caller that sets the final limits after it draws
   % the labels resets each angle. Octave installs no listener, so this
   % function is what keeps an Octave label on its line.

   properties (TestParameter)
      % Slopes of the labeled lines.
      slope = struct('linear', 1, 'earlytime', 3)
   end

   properties (Constant)
      % Limits the label is drawn with, and the wider limits the caller
      % sets afterwards. The second range changes the drawn angle.
      drawlims = [1e0 1e4]
      finallims = [1e0 1e8]

      % An angle no line of these limits takes, used to show that the
      % reset writes the rotation.
      wrongangle = 12

      % Rounding error allowed between two angles, in degrees.
      tolerance = 1e-6
   end

   properties
      % Handles to the private functions under test.
      relayoutloglogtext
      rotatedLogLogText
      loglogangle
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandles(testCase)
         % Store the private function handles once for every test.
         testCase.relayoutloglogtext = baseflow.privatefunction( ...
            'relayoutloglogtext');
         testCase.rotatedLogLogText = baseflow.privatefunction( ...
            'rotatedLogLogText');
         testCase.loglogangle = baseflow.privatefunction('loglogangle');
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Test)
      function test_resetsTheAngleToTheFinalLimits(testCase, slope)
         % The label is drawn with one set of limits and the caller widens
         % them, as pointcloudplot does when an envelope raises the y
         % limit. The reset gives the angle of the widened axes.
         [ax, ht] = testCase.drawlabel(slope);
         set(ax, 'XLim', testCase.finallims, 'YLim', testCase.finallims)
         set(ht, 'Rotation', testCase.wrongangle)
         angle_expected = testCase.loglogangle(ax, slope);

         testCase.relayoutloglogtext(ax);

         testCase.verifyEqual(get(ht, 'Rotation'), angle_expected, ...
            'AbsTol', testCase.tolerance)
      end

      function test_leavesAnUntaggedLabelAlone(testCase)
         % A label of the caller carries no slope, so the reset must not
         % turn it.
         rotation_expected = testCase.wrongangle;
         [ax, ~] = testCase.drawlabel(1);
         hother = text(ax, 10, 10, 'caller label', ...
            'Rotation', rotation_expected);

         testCase.relayoutloglogtext(ax);

         testCase.verifyEqual(get(hother, 'Rotation'), rotation_expected)
      end

      function test_linearAxisKeepsItsAngles(testCase)
         % loglogangle errors on a linear scale, so a scale change must
         % not make the reset error.
         rotation_expected = testCase.wrongangle;
         [ax, ht] = testCase.drawlabel(1);
         set(ax, 'XScale', 'linear')
         set(ht, 'Rotation', rotation_expected)

         testCase.relayoutloglogtext(ax);

         testCase.verifyEqual(get(ht, 'Rotation'), rotation_expected)
      end
   end

   methods (Access = private)
      function [ax, ht] = drawlabel(testCase, slope)
         % Draw one rotated label on a log-log axes of the drawn limits.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', testCase.drawlims, 'YLim', testCase.drawlims)
         ht = testCase.rotatedLogLogText(ax, 10, 10, 'label', slope);
      end
   end
end
