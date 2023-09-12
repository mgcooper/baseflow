classdef TestBaseflow < matlab.unittest.TestCase
   %TESTBASEFLOW Test the baseflow toolbox.
   % 
   % TestBaseflow contains a set of parameterized unit tests:
   %     1) an equality test for a string variable
   %     2) an equality test for a database lookup (basin-name) variable
   %     3) an equality test for a derivative calculation 
   %     4) an equality test for event curve-fitting using nonlinear regression
   %     5) an equality test for parameter conversions
   %     6) an equality test for power law distribution fitting
   %     7) an equality test for aquifer storage estimation
   %     8) an equality test for aquifer thickness estimation
   %
   % Notes:
   %     A) A negative test verifies that the code errors/fails in an
   %        expected way (e.g., the code gives the right error for a
   %        specific bad input)
   % 
   % See also: 

   properties (TestParameter)
      SetupOption = {'install','uninstall','dependencies','addpath','savepath','rmpath','delpath'};
      VarStr = {'Q','dQdt','aQb'};
      DerivMethod = {'CTS'}; % {'ETS','VTS','CTS'}
      FitMethod = {'ols','nls','mean','median'};
      RecessionExponent = {1.0,1.5}; % linear and non-linear
      RecessionParameterNames = {'b','n','alpha'};
      PowerLawExponent = {1.5, 2.0, 2.5, 3.0, 3.5};
      TauValue = {10, 100, 1000};
      PhiValue = {0.001, 0.01, 0.1};
      BasinName = {'ALL_BASINS','KUPARUK R NR DEADHORSE AK'};
      MinEventDuration = {3,6,9};
      RmConvex = {false, true};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_getstring(testCase,VarStr)

         switch VarStr
            case 'Q'
               expectedStr = '$Q$';
            case 'dQdt'
               expectedStr = '$-\mathrm{d}Q/\mathrm{d}t$';
            case 'aQb'
               expectedStr = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';
         end

         % Get actual result
         strActual = baseflow.getstring(VarStr);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(strActual,expectedStr)
      end

      
      %-------------------------------------------
      %-------------------------------------------
      function test_basinname(testCase,BasinName)

         % get the basin name from the database
         ActualName = baseflow.basinname(BasinName);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(BasinName,ActualName);
      end
      
      %-------------------------------------------
      %-------------------------------------------
      function test_getdqdt(testCase,DerivMethod)

         % define the test data
         a = 1e-2;
         b = 1.5;
         q0 = 1;
         [t, q] = baseflow.generateTestData(a,b,q0);

         % Calculate expected result for CTS method
         dq = q-[nan; q(1:end-1)];
         dt = (t(2)-t(1));
         dqdtExpected = dq./dt;

         % Get the actual result
         [~,dqdtActual] = baseflow.getdqdt(t,q,[],DerivMethod);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(dqdtActual,dqdtExpected)

         % for testing:
         % DerivMethod = 'CTS';
         % [~,dqdtActual] = baseflow.getdqdt(t,q,[],DerivMethod);
         % isequal(dqdtActual,dqdtExpected)
         % scatterfit(dqdtActual,dqdtExpected)

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitab(testCase,RecessionExponent,FitMethod)

         % define values to generate the test data
         a = 1e-2;
         q0 = 100;
         t = 1:100;
         b = RecessionExponent;

         % for testing
         % FitMethod = 'ols';
         % b = 1.5;
         % [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         % figure; loglog(q,-dqdt,'o')
         % also useful to see this:
         % baseflow.Qnonlin(a,b,q0,t,true)

         % f = baseflow.fitab(q,dqdt,'mean'); ab = f.ab
         % f = baseflow.fitab(q,dqdt,'ols'); ab = f.ab
         % f = baseflow.fitab(q,dqdt,'nls'); ab = f.ab
         % f = baseflow.fitab(q,dqdt,'median'); ab = f.ab

         % generate the test data
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);

         % fit the data
         switch FitMethod
            case {'mean','median'}
               Fit = baseflow.fitab(q,dqdt,FitMethod,'order',b);
            otherwise
               Fit = baseflow.fitab(q,dqdt,FitMethod);
         end

         % Get the expected result
         abExpected = [a;b];

         % Get the actual result
         abActual = Fit.ab;

         % for testing:
         % f = baseflow.fitab(q,dqdt,FitMethod); abActual = f.ab
         % isequal(abActual,abExpected)

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(abActual,abExpected,'RelTol',[0.01; 0.01])

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_conversions(testCase,RecessionParameterNames)

         switch RecessionParameterNames
            case 'b'
               b = 1.5;
               nExpected = 0;
               nActual = baseflow.conversions(b,'b','n','isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(nActual,nExpected);

            case 'n'
               n = -1;
               bExpected = 1;
               bActual = baseflow.conversions(n,'n','b','isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(bActual,bExpected);

            case 'alpha'
               alpha = 4.0;
               bExpected = 1.25;
               bActual = baseflow.conversions(alpha,'alpha','b','isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(bActual,bExpected);
         end

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_plfitb(testCase,PowerLawExponent)

         % generate power-law distributed test data
         x = (1-rand(10000,1)).^(-1/(PowerLawExponent-1));

         % compute the fit
         [bActual,alphaActual] = baseflow.plfitb(x);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(PowerLawExponent,alphaActual,'AbsTol',0.1);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_aquiferstorage(testCase,RecessionExponent)

         % make test data
         qmin = 1;
         qmax = 100;
         a = 1;
         b = RecessionExponent;

         % compute the expected result
         switch RecessionExponent
            case 1.0
               SminExpected = 1/a*qmin;
               SmaxExpected = 1/a*qmax;

            case 1.5
               SminExpected = 1/a/(2-b).*(qmin.^(2-b));
               SmaxExpected = 1/a/(2-b).*(qmax.^(2-b));
         end

         % get the actual result
         [SminActual,SmaxActual] = baseflow.aquiferstorage(a,b,qmin,qmax);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([SminExpected,SmaxExpected],[SminActual,SmaxActual]);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_aquiferthickness(testCase,RecessionExponent,TauValue,PhiValue)

         % note: this implicitly tests baseflow.conversions

         % make test data
         Qb = 2;
         b = RecessionExponent;
         tau = TauValue;
         phi = PhiValue;

         % compute the expected result
         DExpected = tau/phi/(4-2*b)*Qb;
         SExpected = DExpected*phi;

         % get the actual result
         [DActual,SActual] = baseflow.aquiferthickness(b,tau,phi,Qb);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([DExpected,SExpected],[DActual,SActual]);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_eventfinder(testCase, MinEventDuration, RmConvex)

         % MinEventDuration = 9;
         % RmConvex = true;

         % Generate synthetic data. prec controls how large the test vectors are
         prec = 2;
         [t, q] = prepareEventData(testCase, prec); %#ok<*INUSD>
         [starts, ends, inflect] = eventIndices(testCase, t, prec, RmConvex);

         % Define expected t and q
         tExpected = cell(numel(starts), 1);
         qExpected = cell(numel(starts), 1);
         for n = 1:numel(starts)
            tExpected{n, 1} = transpose(t(starts(n):ends(n)));
            qExpected{n, 1} = transpose(q(starts(n):ends(n)));
         end

         % get the actual result
         [tActual,qActual] = baseflow.eventfinder(t,q,[],'nmin',MinEventDuration, ...
            'fmax',0,'rmax',0,'rmin',0,'rmconvex',RmConvex,'rmnochange',false, ...
            'rmrain',false);

         % % Verify that the actual result matches the expected result to within a
         % difference of up to two elements to account for the +/- 1 day criteria applied
         % in the eventfinder filters.
         for n = 1:numel(tActual)
            [commonT, ia, ib] = intersect(tExpected{n}, tActual{n});
            numdiff = length(tExpected{n}) + length(tActual{n}) - 2*length(commonT);

            if numdiff <= 4
               testCase.verifyEqual(tExpected{n}(ia), tActual{n}(ib));
               testCase.verifyEqual(qExpected{n}(ia), qActual{n}(ib));

               % texp = tExpected{n}(ia);
               % qexp = qExpected{n}(ia);
               % tact = tActual{n}(ib);
               % qact = qActual{n}(ib);
               % assertequal(tExpected{n}(ia), tActual{n}(ib));
               % assertequal(qExpected{n}(ia), qActual{n}(ib));

               % figure;
               % plot(texp, qexp); hold on;
               % plot(tact, qact, ':');

            else
               error('Difference greater than 2 elements detected.');
            end
         end

         % for scripting:
         % assertequal([tActual,qActual], [tExpected,qExpected])

         % For a 1:1 comparison:
         % testCase.verifyEqual([tExpected,qExpected],[tActual,qActual]);

         % Plot the result
         if MinEventDuration == 3
            % For now, use the first test value to determine whether to plot the
            % result. TODO: add a method to plot in a subplot for each test
            % parameter.
            figure; plot(t,q); hold on;
            plot(t(inflect), q(inflect), 'x', 'MarkerSize', 20, 'Color', 'r');

            for n = 1:numel(tActual)
               plot(tExpected{n}, qExpected{n}, 'LineWidth', 2, 'Color', 'k');
               plot(tActual{n},qActual{n},':','Color', 'g');
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

         tExpected = [];
         qExpected = [];

         % figure; plot(tExpected, qExpected, '-o')
         [tActual,qActual] = baseflow.eventfinder(t, q, [], 'nmin', ...
            MinEventDuration, 'fmax', 0, 'rmax', 0, 'rmin', 0, 'rmconvex', ...
            RmConvex, 'rmnochange', false, 'rmrain', false);

         testCase.verifyEqual(tExpected, tActual);
         testCase.verifyEqual(qExpected, qActual);

         % This does not error, it returns empty, so use the above test
         % testCase.verifyError(@() baseflow.eventfinder(t, q, [], 'nmin', ...
         %  MinEventDuration, 'fmax', 0, 'rmax', 0, 'rmin', 0, 'rmconvex', ...
         %  RmConvex, 'rmnochange', false, 'rmrain', false));
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
            % Find the points where the first derivative cos(t) is negative and the
            % second derivative -sin(t) is positive.
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
%       % if tExpected, tActual sizes don't match, try adjusting whether the point
%       % prior to the min is removed. For example, if the test uses this syntax:
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
%       tExpected{1} = transpose(t(ievent1));
%       qExpected{1} = transpose(q(ievent1));
%       tExpected{2} = transpose(t(ievent2));
%       qExpected{2} = transpose(q(ievent2));
%
%       isequal(tExpected{1},tActual{1})
%       isequal(tExpected{2},tActual{2})
%
%       % If that says they are equal, then the issue is with removing the min.
%
%       % Below here is ohter stuff I used for debugging.
%       [size(tExpected{1}); size(tActual{1})]
%       [size(tExpected{2}); size(tActual{2})]
%
%       % depending on which one is missing, reverse the setdiff
%       [val1, i1] = setdiff(tExpected{1}, tActual{1});
%       [val1, i1] = setdiff(tActual{1}, tExpected{1});
%
%       [val2, i2] = setdiff(tExpected{2}, tActual{2})
%       [val2, i2] = setdiff(tActual{2}, tExpected{2})
%
%       loc = ~ismember(tExpected{1}, tActual{1})
%
%       figure; plot(t,q); hold on;
%       plot(tExpected{1},qExpected{1});
%       plot(tExpected{2},qExpected{2});
%       plot(tActual{1},qActual{1},'o','MarkerSize',6);
%       plot(tActual{2},qActual{2},'o');
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
