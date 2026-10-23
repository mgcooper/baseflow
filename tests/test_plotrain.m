classdef test_plotrain < matlab.unittest.TestCase
   %TEST_PLOTRAIN Test the rain circles of pointcloudplot and plotdqdt.
   %
   % Both functions call the private plotrain. It draws one open magenta
   % circle at each point that has rain. The circle size is the marker size
   % of the plotted points plus sqrt(pi*rain^2). With no rain above zero,
   % including NaN rain, it draws no circle and returns nan. Each case runs
   % one caller on the same data, so the two figures keep the same circles.
   %
   % See also: test_pointcloudplot, test_plotdqdt

   properties (TestParameter)
      % The public functions that draw the rain circles.
      caller = {'pointcloudplot', 'plotdqdt'}

      % Rain with no value above zero: zero everywhere, or NaN everywhere,
      % as an event without a rain record gives.
      dryrain = struct('zero', 0, 'nan', NaN)
   end

   properties (Constant)
      % The rain at two wet points, in mm. The other points are dry.
      wetindex = [1 3]
      wetrain = [5 2]

      % Rounding error allowed in a position. plotdqdt plots exp(log(q)),
      % which differs from q in the last bits.
      reltol = 1e-12
   end

   properties
      % Point-cloud test data.
      q
      dqdt
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function preparecase(testCase)
         % Nonlinear test data (b = 1.5), as in test_plotdqdt.
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~, testCase.q, testCase.dqdt] = baseflow.generateTestData( ...
            a, b, q0, t);
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Close the figures each case opens (see tests/closenewfigs.m).
         testCase.figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(testCase.figsbefore));
      end
   end

   methods (Access = private)
      function [hrain, hpoints] = draw(testCase, caller, rain)
         %DRAW Draw the point cloud with one caller and return its handles.
         %
         %  [hrain, hpoints] = draw(testCase, caller, rain) returns the
         %  rain circle handles and the handle of the plotted points.
         switch caller
            case 'pointcloudplot'
               out = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
                  'rain', rain);
               hrain = out.hrain;
               hpoints = out.scatter;
            case 'plotdqdt'
               h = baseflow.plotdqdt(testCase.q, testCase.dqdt, 'rain', rain);
               hrain = h.hrain;
               hpoints = h.scatter;
         end
      end
   end

   methods (Test)
      function test_circlesMarkTheWetPoints(testCase, caller)
         % One circle sits on each wet point, and its size grows with the
         % rain by sqrt(pi*rain^2) over the size of the plotted points.
         rain = zeros(size(testCase.q));
         rain(testCase.wetindex) = testCase.wetrain;

         [hrain, hpoints] = testCase.draw(caller, rain);

         x_expected = testCase.q(testCase.wetindex);
         y_expected = -testCase.dqdt(testCase.wetindex);
         size_expected = get(hpoints, 'MarkerSize') ...
            + sqrt(pi .* testCase.wetrain(:) .^ 2);

         testCase.verifyNumElements(hrain, numel(testCase.wetindex))
         [x_returned, order] = sort(cell2mat(get(hrain(:), 'XData')), ...
            'descend');
         y_returned = cell2mat(get(hrain(:), 'YData'));
         size_returned = cell2mat(get(hrain(:), 'MarkerSize'));
         testCase.verifyEqual(x_returned, x_expected(:), ...
            'RelTol', testCase.reltol)
         testCase.verifyEqual(y_returned(order), y_expected(:), ...
            'RelTol', testCase.reltol)
         testCase.verifyEqual(size_returned(order), size_expected, ...
            'RelTol', testCase.reltol)
         testCase.verifyEqual(get(hrain(1), 'Color'), [1 0 1])
         testCase.verifyEqual(get(hrain(1), 'MarkerFaceColor'), 'none')
      end

      function test_noRainDrawsNoCircle(testCase, caller, dryrain)
         % With no rain above zero, plotrain draws nothing and returns nan,
         % which keeps the rain entry out of the legend. NaN rain makes the
         % sum NaN, so a test of the sum alone draws no circle and leaves
         % the output unassigned.
         rain = dryrain .* ones(size(testCase.q));

         hrain = testCase.draw(caller, rain);

         testCase.verifyTrue(isscalar(hrain) && isnan(hrain))
      end
   end
end
