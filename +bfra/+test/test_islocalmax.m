% test bfra.util.islocalmax
function tests = test_islocalmax
    tests = functiontests(localfunctions);
end

function setup(testCase)

   % generate test data
   [T,Q] = bfra.testdata("example");
   
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

function teardown(testCase)

end

function test_peakfinder(testCase)

   customislocalmax = bfra.privatefunction('islocalmax');
   
   A = testCase.TestData.A;
   expectedPeakIndex = testCase.TestData.expectedPeakIndex;
   
   [tf_islocalmax,p_islocalmax] = islocalmax(A); %#ok<*ASGLU> 
   try
      [~,i_findpeaks,~,p_findpeaks] = findpeaks(A);
   catch
   end
   tf_custom = customislocalmax(A);
   
   % get the index of the peak
   i_peakfinder = bfra.deps.peakfinder(A); %#ok<*NASGU> 
   i_islocalmax = find(tf_islocalmax);
   i_bfracustom = find(tf_custom);

   % compare peak locations
   msg = 'bfra.util.islocalmax failed to identify the peak correctly';
   testCase.verifyEqual(expectedPeakIndex, i_bfracustom, msg);

   %    assert(isequal(i_peakfinder, i_islocalmax, i_bfracustom))
   %
   %    % compare peak prominence
   %    assert(isequal(p_islocalmax(p_islocalmax>0), p_findpeaks(p_findpeaks>0)))
end

% Below here is script-based test

% % test bfra.util.islocalmax
% 
% % generate test data
% 
% [T,Q,R] = bfra.testdata("example");
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
% datetick; title('test: bfra.util.islocalmax'); legend
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
% tf_custom = bfra.util.islocalmax(A);
% 
% % get the index of the peak
% i_peakfinder = bfra.deps.peakfinder(A);
% i_islocalmax = find(tf_islocalmax);
% i_bfracustom = find(tf_custom);
% 
% % compare peak locations
% assert(isequal(i_peakfinder, i_islocalmax, i_bfracustom))
% 
% % compare peak prominence
% assert(isequal(p_islocalmax(p_islocalmax>0), p_findpeaks(p_findpeaks>0)))
