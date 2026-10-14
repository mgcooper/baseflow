classdef test_islocalmax < matlab.unittest.TestCase
   %TEST_ISLOCALMAX Test baseflow/private/islocalmax.m
   %
   % The private islocalmax wraps peakfinder, because Octave has no
   % islocalmax. It must find the peak of a window of the example record,
   % and the same interior maxima as the MATLAB function of the same name.
   % tests/test_islocalmin.m holds the same signals for the minima.

   properties (TestParameter)
      % Short signals with one peak, one valley, or several extrema. The
      % one-extremum signals check the peakfinder monotone branch.
      ExtremaSignal = struct( ...
         'onepeak', [1 2 3 2 1], ...
         'peakthenfall', [2 3 1 0 -1], ...
         'threepoints', [0 1 0], ...
         'twopeaks', [1 2 3 2 5 1], ...
         'peakvalleypeak', [10 12 15 13 11 12 11], ...
         'onevalley', [10 9 8 9 10]);
   end

   properties
      % The open-figure snapshot and the test_peakLocations fixture data.
      TestData
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Snapshot open figures; teardown closes only figures created here.
         testCase.TestData.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function teardown(testCase)
         % Close the figures the test created (see tests/closenewfigs.m).
         closenewfigs(testCase.TestData.figsbefore)
      end
   end

   methods (Test)

      function test_peakLocations(testCase)
         % Compare peak locations from the custom islocalmax, peakfinder, and the
         % builtin islocalmax. Note: a local test named test_peakfinder resolves
         % to the tests/test_peakfinder.m class and breaks suite creation.

         % Build the example-record window and its expected peaks.
         preparepeakdata(testCase);

         customislocalmax = baseflow.privatefunction('islocalmax');

         A = testCase.TestData.A;
         peak_expected = testCase.TestData.expectedPeakIndex;

         [tf_islocalmax,p_islocalmax] = islocalmax(A); %#ok<*ASGLU>
         try
            [~,i_findpeaks,~,p_findpeaks] = findpeaks(A);
         catch
         end
         tf_custom = customislocalmax(A);

         % get the index of the peak
         i_peakfinder = baseflow.deps.peakfinder(A); %#ok<*NASGU>
         i_islocalmax = find(tf_islocalmax);
         peak_returned = find(tf_custom);

         % compare peak locations
         msg = 'baseflow/private/islocalmax failed to identify the peak correctly';
         testCase.verifyEqual(peak_returned, peak_expected, msg);

         % All three implementations agree on the fixture data. This check runs
         % the index comparison from the commented script block below. The
         % prominence comparison against findpeaks does not run: findpeaks
         % needs the undeclared Signal Processing Toolbox, and the index
         % comparison already checks that the implementations agree.
         agreement_returned = {i_peakfinder(:), i_islocalmax(:)};
         agreement_expected = {peak_returned(:), peak_returned(:)};
         testCase.verifyEqual(agreement_returned, agreement_expected, ...
            'peakfinder, islocalmax, and the custom islocalmax disagree')
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_islocalextrema(testCase, ExtremaSignal)

         % The private peakfinder wrappers must find the same interior
         % extrema as the MATLAB functions of the same name
         customfunction = baseflow.privatefunction('islocalmax');
         expected = islocalmax(ExtremaSignal);
         returned = customfunction(ExtremaSignal);
         testCase.verifyEqual(returned, expected)
      end
   end

   methods (Access = private)
      function preparepeakdata(testCase)
         %PREPAREPEAKDATA Build the test_peakLocations fixture.
         %
         %  preparepeakdata(testCase) loads a window of the example
         %  record, draws it, and stores the signal and its expected
         %  peak, unique, and inflection indices in testCase.TestData.

         % generate test data
         [T,Q] = baseflow.loadExampleData();

         % Select a fixed window of the example record as the test signal.
         t = T(100:200);
         A = Q(100:200);
         s = sign(diff(A));

         % Find points where the second order difference is negative and pad the
         % result to be of the correct size. Note: for the simplest case, the local
         % max can be found here, but end points are found at the end.
         pad = true(1, size(A,2));
         maxVals = [~pad; diff(s) < 0; ~pad];

         % generate test figure
         figure; plot(t,A, 'HandleVisibility', 'off'); hold on;
         plot(t(s==0),A(s==0),'o', 'HandleVisibility', 'off')
         plot(t(s==1),A(s==1),'o', 'HandleVisibility', 'off')
         plot(t(s==-1),A(s==-1),'o', 'HandleVisibility', 'off')
         scatter(t(maxVals),A(maxVals), 100, 'filled', 'displayname', 'Peak')
         datetick; title('test: islocalmax'); legend

         % Ignore repeated values.
         uniquePts = [pad; (A(2:end,:) ~= A(1:(end-1),:))];
         if isfloat(A) && any(isnan(A(:)))
            uniquePts = uniquePts & ...
               [pad; ~(isnan(A(2:end,:)) & isnan(A(1:(end-1),:)))];
         end

         % Get the inflection points: every place where the first order
         % difference of A changes sign.  Remove duplicate points.  Consider end
         % points inflection points.
         inflectionPts = [pad; (s(1:(end-1),:) ~= s(2:end, :)) & ...
            uniquePts(2:(end-1),:); pad];

         % Check the result
         expectedPeakIndex = find(maxVals);
         expectedUniquePoints = find(uniquePts);
         expectedInflectionPoints = find(inflectionPts);

         % Save the test data
         testCase.TestData.A = A;
         testCase.TestData.expectedPeakIndex = expectedPeakIndex;
         testCase.TestData.expectedUniquePoints = expectedUniquePoints;
         testCase.TestData.expectedInflectionPoints = expectedInflectionPoints;

      end
   end
end

% Below here is script-based test

% % test baseflow/private/islocalmax.m
%
% % generate test data
%
% [T,Q,R] = baseflow.loadExampleData();
%
% t = T(100:200);
% A = Q(100:200);
% s = sign(diff(A));
%
% % Find points where the second order difference is negative and pad the
% % result to be of the correct size. Note: for the simplest case, the local
% % max can be found here, but end points are found at the end.
% pad = true(1, size(A,2));
% maxVals = [~pad; diff(s) < 0; ~pad];
%
% % generate test figure
% figure; plot(t,A, 'HandleVisibility', 'off'); hold on;
% plot(t(s==0),A(s==0),'o', 'HandleVisibility', 'off')
% plot(t(s==1),A(s==1),'o', 'HandleVisibility', 'off')
% plot(t(s==-1),A(s==-1),'o', 'HandleVisibility', 'off')
% scatter(t(maxVals),A(maxVals), 100, 'filled', 'displayname', 'Peak')
% datetick; title('test: baseflow/private/islocalmax'); legend
%
% % Ignore repeated values.
% uniquePts = [pad; (A(2:end,:) ~= A(1:(end-1),:))];
% if isfloat(A) && any(isnan(A(:)))
%    uniquePts = uniquePts & ...
%       [pad; ~(isnan(A(2:end,:)) & isnan(A(1:(end-1),:)))];
% end
%
% % Get the inflection points: every place where the first order
% % difference of A changes sign.  Remove duplicate points.  Consider end
% % points inflection points.
% inflectionPts = [pad; (s(1:(end-1),:) ~= s(2:end, :)) & ...
%    uniquePts(2:(end-1),:); pad];
%
% % Check the result
% % find(maxVals)
% % find(uniquePts)
% % find(inflectionPts)
%
% %% test peak location and prominence detection
% [tf_islocalmax,p_islocalmax] = islocalmax(A);
% try
%    [~,i_findpeaks,~,p_findpeaks] = findpeaks(A);
% catch
% end
% tf_custom = customislocalmax(A);
%
% % get the index of the peak
% i_peakfinder = baseflow.deps.peakfinder(A);
% i_islocalmax = find(tf_islocalmax);
% i_baseflowcustom = find(tf_custom);
%
% % compare peak locations
% assert(isequal(i_peakfinder, i_islocalmax, i_baseflowcustom))
%
% % compare peak prominence
% assert(isequal(p_islocalmax(p_islocalmax>0), p_findpeaks(p_findpeaks>0)))
