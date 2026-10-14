classdef test_eventfinder < matlab.unittest.TestCase
   %TEST_EVENTFINDER Test the events baseflow.eventfinder finds in a sine.
   %
   % The signal 1 + sin(t) has known maxima, minima, and inflection points,
   % so the expected declining and concave-up declining segments follow
   % from its derivatives. The defaults and the rmax guard of eventfinder
   % are integration checks in TestBaseflow.

   properties (TestParameter)
      % The minimum event lengths and the rmconvex option of each case.
      MinEventDuration = {3,6,9};
      RmConvex = {false, true};
   end

   properties (Access = private)
      % Open-figure snapshot taken before each test. The method teardown
      % closes only figures the test created, so a full suite run leaves
      % zero open figures without touching pre-existing user figures.
      figsbefore
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

      %-------------------------------------------
      %-------------------------------------------
      function test_findsDecliningSegments(testCase, MinEventDuration, RmConvex)

         % MinEventDuration = 9;
         % RmConvex = true;

         % Generate synthetic data. prec controls how large the test vectors are
         prec = 2;
         [t, q] = prepareEventData(testCase, prec); %#ok<*INUSD>
         [starts, ends, inflect] = eventIndices(testCase, t, prec, RmConvex);

         % Define expected t and q
         t_expected = cell(numel(starts), 1);
         q_expected = cell(numel(starts), 1);
         for n = 1:numel(starts)
            t_expected{n, 1} = transpose(t(starts(n):ends(n)));
            q_expected{n, 1} = transpose(q(starts(n):ends(n)));
         end

         % get the actual result. The synthetic signal has no rainfall record.
         % rmnochange is false, so rmax has no effect, but it must be > 1.
         [t_returned,q_returned] = baseflow.eventfinder(t,q,[], ...
            'nmin',MinEventDuration,'fmax',0,'rmax',2,'rmin',0, ...
            'rmconvex',RmConvex,'rmnochange',false,'rmrain',false);

         % Largest allowed count of event times that are in only one of the
         % expected and returned series (see numdiff below)
         maxdiff = 4;

         % % Verify that the actual result matches the expected result to within
         % a difference of up to two elements to account for the +/- 1 day
         % criteria applied in the eventfinder filters.
         for n = 1:numel(t_returned)
            [commonT, ia, ib] = intersect(t_expected{n}, t_returned{n});
            numdiff = length(t_expected{n}) + length(t_returned{n}) ...
               - 2*length(commonT);

            if numdiff <= maxdiff
               testCase.verifyEqual(t_returned{n}(ib), t_expected{n}(ia));
               testCase.verifyEqual(q_returned{n}(ib), q_expected{n}(ia));
            else
               error('Difference greater than 2 elements detected.');
            end
         end

         % Plot the result
         if MinEventDuration == 3
            % For now, use the first test value to determine whether to plot the
            % result. TODO: add a method to plot in a subplot for each test
            % parameter.
            figure; plot(t,q); hold on;
            plot(t(inflect), q(inflect), 'x', 'MarkerSize', 20, 'Color', 'r');

            for n = 1:numel(t_returned)
               plot(t_expected{n}, q_expected{n}, 'LineWidth', 2, 'Color', 'k');
               plot(t_returned{n},q_returned{n},':','Color', 'g');
            end

            % Adjust legend and title based on rmconvex
            if RmConvex
               legend('Signal', 'Inflection Points',  ...
                  'True Concave Up Declining Flow', 'eventfinder');
               title('test rmconvex')
            else
               legend('Signal', 'Inflection Points', ...
                  'True Declining Flow', 'eventfinder');
               title('test eventfinder')
            end
         end
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_MinEventDuration(testCase, MinEventDuration, RmConvex)

         % Generate synthetic data. prec controls how large the test vectors are
         prec = 2;
         [t, q] = prepareEventData(testCase, prec);
         [starts, ends] = eventIndices(testCase, t, prec, RmConvex);

         % test an event that is shorter than the MinEventDuration
         idx = sort(randi(ends(1)-starts(1), MinEventDuration-1, 1));
         t = t(starts(1)+idx);
         q = q(starts(1)+idx);

         t_expected = [];
         q_expected = [];

         % figure; plot(t_expected, q_expected, '-o')
         % The synthetic signal has no rainfall record. rmnochange is false,
         % so rmax has no effect, but it must be > 1.
         [t_returned,q_returned] = baseflow.eventfinder(t, q, [], 'nmin', ...
            MinEventDuration, 'fmax', 0, 'rmax', 2, 'rmin', 0, 'rmconvex', ...
            RmConvex, 'rmnochange', false, 'rmrain', false);

         testCase.verifyEqual(t_returned, t_expected);
         testCase.verifyEqual(q_returned, q_expected);

         % eventfinder returns empty, not an error, for an event shorter than
         % nmin; the equality checks above cover that case.
      end
   end

   methods (Access = private) % Helper methods

      function [t, q] = prepareEventData(testCase, prec) %#ok<*INUSD>
         % This function handles some common operations related to test data

         if nargin < 2
            prec = 2; % precision, controls how large the test vectors are
         end

         % generate synthetic data
         dpi = 10^-prec;
         t = -2*pi:dpi:2*pi;
         q = 1 + sin(t);
      end

      function [starts, ends, inflect] = eventIndices(testCase, t, prec, RmConvex)

         if RmConvex
            % Find the points where the first derivative cos(t) is negative and
            % the second derivative -sin(t) is positive.
            idxconcave = find(cos(t) < 0 & (-sin(t)) > 0);
            intervals = [find(diff(idxconcave) ~= 1)' numel(idxconcave)];
            starts = [idxconcave(1); idxconcave(intervals(1:end-1) + 1)];
            ends = idxconcave(intervals);

            % Inflection points where the second derivative equals zero
            inflect = find(abs(-sin(t)) <= 10^-prec);

         else
            % Find the maxima and minima (where d/dt sin(t) == 0)
            idxminmax = find(round(cos(t),prec)==0);
            starts = idxminmax(1:2:end); % +1 or +2 depending on eventfinder
            ends = idxminmax(2:2:end); % -1
            inflect = idxminmax;
         end
      end
   end
end


%       % for debugging test_eventfinder
%       % --------------
%
%       % if t_expected, t_returned sizes don't match, try adjusting whether the
%       % point prior to the min is removed. For example, if the test uses this
%       % syntax:
%       %
%       % ievent = idx(n,1)+2 : idx(n,2);
%       %
%       % Then try changing it to:
%       %
%       % ievent = idx(n,1)+2 : idx(n,2) - 1;
%       %
%       % i.e., remove the one prior to the min.
%       %
%       % and visa versa
%
%       % Try removing the min, then see if they are equal
%       ievent1 = idx(1,1)+2 : idx(1,2)-1;
%       ievent2 = idx(2,1)+2 : idx(2,2)-1;
%
%       % Try NOT removing the min
%       % ievent1 = idx(1,1)+2 : idx(1,2);
%       % ievent2 = idx(2,1)+2 : idx(2,2);
%
%       t_expected{1} = transpose(t(ievent1));
%       q_expected{1} = transpose(q(ievent1));
%       t_expected{2} = transpose(t(ievent2));
%       q_expected{2} = transpose(q(ievent2));
%
%       isequal(t_expected{1},t_returned{1})
%       isequal(t_expected{2},t_returned{2})
%
%       % If that says they are equal, then the issue is with removing the min.
%
%       % Below here is ohter stuff I used for debugging.
%       [size(t_expected{1}); size(t_returned{1})]
%       [size(t_expected{2}); size(t_returned{2})]
%
%       % depending on which one is missing, reverse the setdiff
%       [val1, i1] = setdiff(t_expected{1}, t_returned{1});
%       [val1, i1] = setdiff(t_returned{1}, t_expected{1});
%
%       [val2, i2] = setdiff(t_expected{2}, t_returned{2})
%       [val2, i2] = setdiff(t_returned{2}, t_expected{2})
%
%       loc = ~ismember(t_expected{1}, t_returned{1})
%
%       figure; plot(t,q); hold on;
%       plot(t_expected{1},q_expected{1});
%       plot(t_expected{2},q_expected{2});
%       plot(t_returned{1},q_returned{1},'o','MarkerSize',6);
%       plot(t_returned{2},q_returned{2},'o');
%
%       % minima should be at -pi/2, 3*pi/2
%       % maxima should be at pi/2, -3*pi/2
%       s1 = find(t+3*pi/2>0,1,'first')-1;
%       e1 = find(t+pi/2>0,1,'first')-1;
%       s2 = find(t-pi/2>0,1,'first')-1;
%       e2 = find(t-3*pi/2>0,1,'first')-1;
%
%       % remove the peak + 1 day, and the min
%       s1 = s1+2; s2 = s2+2;
%       e1 = e1-1; e2 = e2-1;
