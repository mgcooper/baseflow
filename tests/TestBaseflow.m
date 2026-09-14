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
   %     9) an equality test for the fitevents 'ctsmethod' option
   %    10) an equality test for the fitab 'ols' method against the Curve
   %        Fitting Toolbox fit and confint
   %
   % Notes:
   %     A) A negative test verifies that the code errors/fails in an
   %        expected way (e.g., the code gives the right error for a
   %        specific bad input)
   % 
   % See also: test_internal

   properties (TestParameter)
      SetupOption = {'install','uninstall','dependencies','addpath','savepath','rmpath','delpath'};
      VarStr = {'Q','dQdt','aQb'};
      DerivMethod = {'CTS'}; % {'ETS','VTS','CTS'}
      CtsMethod = {'B1','B2','F1','F2','C2','C4'};
      FitMethod = {'ols','nls','mean','median'};
      RecessionExponent = {1.0,1.5}; % linear and non-linear
      OrderOption = struct('default', {{}}, 'order1', {{'order', 1}});
      RecessionParameterNames = {'b','n','alpha'};
      PowerLawExponent = {1.5, 2.0, 2.5, 3.0, 3.5};
      TauValue = {10, 100, 1000};
      PhiValue = {0.001, 0.01, 0.1};
      BasinName = {'ALL_BASINS','KUPARUK R NR DEADHORSE AK'};
      MinEventDuration = {3,6,9};
      RmConvex = {false, true};
   end

   properties (Access = private)
      % Open-figure snapshot taken before each test. The method teardown
      % closes only figures the test created, so a full suite run leaves
      % zero open figures without touching pre-existing user figures.
      figsbefore

      % The first recession event in the example data. The class setup
      % builds it once so the fitevents tests do not repeat getevents.
      firstevent
   end

   methods (TestClassSetup)
      function loadfirstevent(testCase)
         % Detect events in the example data. Keep only the first event so
         % each fitevents call fits one event and the tests stay fast.
         [T, Q, R] = baseflow.loadExampleData();
         Events = baseflow.getevents(T, Q, R);
         ievent = Events.eventTags == 1;
         testCase.firstevent = struct( ...
            'eventTime', Events.eventTime(ievent), ...
            'eventFlow', Events.eventFlow(ievent), ...
            'eventRain', Events.eventRain(ievent), ...
            'eventTags', Events.eventTags(ievent));
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

      %-------------------------------------------
      %-------------------------------------------
      function test_getstring(testCase,VarStr)

         switch VarStr
            case 'Q'
               expected = '$Q$';
            case 'dQdt'
               expected = '$-\mathrm{d}Q/\mathrm{d}t$';
            case 'aQb'
               expected = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';
         end

         % Get actual result
         returned = baseflow.getstring(VarStr);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected)
      end


      %-------------------------------------------
      %-------------------------------------------
      function test_basinname(testCase,BasinName)

         % get the basin name from the database
         returned = baseflow.basinname(BasinName);

         % A valid basin name maps to itself
         expected = BasinName;

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected);
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
         expected = dq./dt;

         % Get the actual result. The test data has no rainfall record.
         [~,returned] = baseflow.getdqdt(t,q,[],DerivMethod);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected)

         % for testing:
         % DerivMethod = 'CTS';
         % [~,returned] = baseflow.getdqdt(t,q,[],DerivMethod);
         % isequal(returned,expected)
         % scatterfit(returned,expected)

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
         expected = [a;b];

         % Get the actual result
         returned = Fit.ab;

         % for testing:
         % f = baseflow.fitab(q,dqdt,FitMethod); returned = f.ab
         % isequal(returned,expected)

         % Allow a 1 percent relative error in each of a and b
         tol = [0.01; 0.01];

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected,'RelTol',tol)

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitab_order1(testCase,FitMethod)

         % generate nonlinear (b = 1.5) test data
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);

         % fit with 'order' = 1: methods that estimate the slope redirect
         % to 'mean'; 'mean' and 'median' force the slope directly
         Fit = baseflow.fitab(q,dqdt,FitMethod,'order',1);

         % Verify the fitted exponent is forced to 1 (linear reservoir)
         returned = Fit.ab(2); % Fit.ab stores [a; b]
         expected = 1;
         testCase.verifyEqual(returned,expected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitab_order1_envelope(testCase)

         % generate test data with deterministic scatter so the 0.95
         % quantile envelope and the mean give different intercepts
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         q = q .* (1 + 0.2*sin((1:numel(q))'));

         % 'envelope' with 'order' = 1 must stay an envelope fit through
         % 'refqtls'; it must not redirect to the 'mean' method
         FitE = baseflow.fitab(q,dqdt,'envelope', ...
            'refqtls',[0.95 0.95],'order',1);
         FitM = baseflow.fitab(q,dqdt,'mean','order',1);

         % Verify the slope is 1 and the intercept differs from the mean
         % fit. Fit.ab stores [a; b].
         b_returned = FitE.ab(2);
         b_expected = 1;
         testCase.verifyEqual(b_returned,b_expected);
         a_returned = FitE.ab(1);
         a_notexpected = FitM.ab(1);
         testCase.verifyNotEqual(a_returned,a_notexpected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitab_order_scope(testCase,OrderOption)

         % generate nonlinear (b = 1.5) test data
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);

         % 'qtl' passes 'order' to quantreg as the polynomial degree, so
         % 'order' = 1 must run quantile regression, not the 'mean' method.
         % 'qtl' with no 'order' must apply the quantreg default of 1 and
         % run quantile regression. A nan parser default for 'order' crashes it.
         Fit = baseflow.fitab(q,dqdt,'qtl',OrderOption{:});
         returned = Fit.fselect;
         expected = 'qtl';
         testCase.verifyEqual(returned,expected);

         % 'mle' is unsupported and must error with or without 'order' = 1
         testCase.verifyError( ...
            @() baseflow.fitab(q,dqdt,'mle',OrderOption{:}), ?MException);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitab_ols_confint(testCase)

         % The Curve Fitting Toolbox fit and confint give independent expected
         % values for the 'ols' method, so skip the test without the toolbox
         testCase.assumeFalse(isempty(ver('curvefit')), ...
            'test_fitab_ols_confint requires the Curve Fitting Toolbox');

         % generate nonlinear (b = 1.5) test data with deterministic
         % scatter, unequal weights, and a mask that drops every fifth point
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         k = (1:numel(q))';
         q = q .* (1 + 0.2*sin(k));
         weights = 1 + mod(k,3);
         mask = mod(k,5) ~= 0;
         alpha = 0.9;

         % fit -dq/dt = aQ^b with the 'ols' method
         Fit = baseflow.fitab(q,dqdt,'ols','weights',weights, ...
            'mask',mask,'alpha',alpha);

         % Expected values: a weighted poly1 fit of log(-dq/dt) on log(q).
         % fitab documents that masked points get zero weight.
         fopts = fitoptions('Method','LinearLeastSquares', ...
            'Weights',weights.*mask);
         f = fit(log(q),log(-dqdt),'poly1',fopts);

         % coeffvalues is [slope intercept]. confint has rows [lower; upper]
         % with the same column order. Fit stores a = exp(intercept).
         p = coeffvalues(f);
         pci = confint(f,alpha);
         ab_expected = [exp(p(2)); p(1)];
         ci_expected = [exp(pci(:,2)'); pci(:,1)'];

         ab_returned = Fit.ab;
         ci_returned = [Fit.aL Fit.aH; Fit.bL Fit.bH];

         % Both are least-squares solutions, so allow rounding error only
         tol = 1e-10;
         testCase.verifyEqual(ab_returned,ab_expected,'RelTol',tol);
         testCase.verifyEqual(ci_returned,ci_expected,'RelTol',tol);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_plotdqdt_labelplot(testCase)

         % generate nonlinear (b = 1.5) test data
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);

         % Count refline arrows by their annotation class
         arrowclass = 'matlab.graphics.shape.Arrow';

         % 'labelplot' defaults to false: no refline arrow annotations
         baseflow.plotdqdt(q,dqdt);
         narrows_returned = numel(findall(gcf,'-isa',arrowclass));
         narrows_expected = 0;
         testCase.verifyEqual(narrows_returned,narrows_expected);
         % Close only the figure this test created, so a pre-existing user
         % figure survives; plotdqdt opens a fresh figure for the next call.
         closenewfigs(testCase.figsbefore)

         % 'labelplot' true draws at least one refline arrow (see
         % labelReflines)
         baseflow.plotdqdt(q,dqdt,'labelplot',true);
         nlabeled_returned = numel(findall(gcf,'-isa',arrowclass));
         testCase.verifyGreaterThan(nlabeled_returned,0);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitevents_fitorder(testCase)

         % build a one-event Events structure from nonlinear test data
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         % Note: generateTestData returns its own t, sized to match q
         [t,q] = baseflow.generateTestData(a,b,q0,t);
         Events.eventTime = t;
         Events.eventFlow = q;
         Events.eventRain = zeros(size(q));
         Events.eventTags = ones(size(q));

         % fitevents must pass 'fitorder' to fitab so the event is fit
         % with a linear reservoir model
         [~,Results] = baseflow.fitevents(Events,'fitorder',1);

         % Verify a fit was returned and the exponent is forced to 1
         returned = Results.b;
         testCase.verifyNotEmpty(returned);
         expected = ones(size(returned));
         testCase.verifyEqual(returned,expected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitevents_ctsmethod(testCase,CtsMethod)

         % fitevents must pass 'ctsmethod' to getdqdt, so the dq/dt it
         % stores for the event equals a direct getdqdt call
         Event = testCase.firstevent;
         [~,expected] = baseflow.getdqdt(Event.eventTime, ...
            Event.eventFlow,Event.eventRain,'CTS','ctsmethod',CtsMethod);
         returned = baseflow.fitevents(Event,'derivmethod','CTS', ...
            'ctsmethod',CtsMethod,'plotfits',false);
         testCase.verifyEqual(returned.dqdt,expected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_setopts_ctsmethod(testCase)

         % The fitevents options default to the traditional backward
         % first-order stencil
         returned = baseflow.setopts('fitevents');
         expected = 'B1';
         testCase.verifyEqual(returned.ctsmethod,expected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_conversions(testCase,RecessionParameterNames)

         switch RecessionParameterNames
            case 'b'
               % convert the recession exponent b to n for a flat aquifer
               b = 1.5;
               expected = 0; % n = (3 - 2b)/(b - 2)
               returned = baseflow.conversions(b,'b','n','isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(returned,expected);

            case 'n'
               % convert the conductivity exponent n to b for a flat aquifer
               n = -1;
               expected = 1; % b = (2n + 3)/(n + 2)
               returned = baseflow.conversions(n,'n','b','isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(returned,expected);

            case 'alpha'
               % convert the power law exponent alpha to b
               alpha = 4.0;
               expected = 1.25; % b = 1 + 1/alpha
               returned = baseflow.conversions(alpha,'alpha','b', ...
                  'isflat',true);

               % Verify that the actual result matches the expected result
               testCase.verifyEqual(returned,expected);
         end

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_plfitb(testCase,PowerLawExponent)

         % generate power-law distributed test data
         x = (1-rand(10000,1)).^(-1/(PowerLawExponent-1));

         % compute the fit
         [~,returned] = baseflow.plfitb(x); % the second output is alpha
         expected = PowerLawExponent;

         % The estimate from random samples varies. Allow 0.1 absolute error.
         tol = 0.1;

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected,'AbsTol',tol);

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
               Smin_expected = 1/a*qmin;
               Smax_expected = 1/a*qmax;

            case 1.5
               Smin_expected = 1/a/(2-b).*(qmin.^(2-b));
               Smax_expected = 1/a/(2-b).*(qmax.^(2-b));
         end

         % get the actual result
         [Smin_returned,Smax_returned] = baseflow.aquiferstorage( ...
            a,b,qmin,qmax);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([Smin_returned,Smax_returned], ...
            [Smin_expected,Smax_expected]);

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
         D_expected = tau/phi/(4-2*b)*Qb;
         S_expected = D_expected*phi;

         % get the actual result
         [D_returned,S_returned] = baseflow.aquiferthickness(b,tau,phi,Qb);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual([D_returned,S_returned],[D_expected,S_expected]);

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
         t_expected = cell(numel(starts), 1);
         q_expected = cell(numel(starts), 1);
         for n = 1:numel(starts)
            t_expected{n, 1} = transpose(t(starts(n):ends(n)));
            q_expected{n, 1} = transpose(q(starts(n):ends(n)));
         end

         % get the actual result. The synthetic signal has no rainfall record.
         [t_returned,q_returned] = baseflow.eventfinder(t,q,[], ...
            'nmin',MinEventDuration,'fmax',0,'rmax',0,'rmin',0, ...
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
         % The synthetic signal has no rainfall record.
         [t_returned,q_returned] = baseflow.eventfinder(t, q, [], 'nmin', ...
            MinEventDuration, 'fmax', 0, 'rmax', 0, 'rmin', 0, 'rmconvex', ...
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
