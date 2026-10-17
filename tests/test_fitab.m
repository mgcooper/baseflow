classdef test_fitab < matlab.unittest.TestCase
   %TEST_FITAB Test the fit methods and options of baseflow.fitab.
   %
   % Each test fits -dQ/dt = aQ^b to baseflow.generateTestData output with
   % known a and b. The 'ols' confidence test compares fitab with the
   % Curve Fitting Toolbox fit and confint.

   properties (TestParameter)
      % The fit methods, the true recession exponents of the test data,
      % and the 'order' option of the 'qtl' scope test.
      FitMethod = {'ols','nls','mean','median'};
      RecessionExponent = {1.0,1.5}; % linear and non-linear
      OrderOption = struct('default', {{}}, 'order1', {{'order', 1}});

      % The methods that fix the slope of the line, 1 by default.
      FixedSlopeMethod = {'mean','median','envelope'};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_recoversKnownParameters(testCase,RecessionExponent,FitMethod)

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
         % fitab documents that masked points take no part in the fit, so
         % exclude them, which also removes them from the degrees of freedom.
         fopts = fitoptions('Method','LinearLeastSquares', ...
            'Weights',weights,'Exclude',~mask);
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

      function test_nlsIntervalFollowsAlpha(testCase)
         % alpha is a confidence level, so the 95% interval is wider than
         % the 68% one by the ratio of their t quantiles. Reading alpha as
         % a significance level inverts the ratio.
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         q = q .* (1 + 0.2*sin((1:numel(q))'));
         Fit68 = baseflow.fitab(q,dqdt,'nls','alpha',0.68);
         Fit95 = baseflow.fitab(q,dqdt,'nls','alpha',0.95);
         dfe = Fit68.N - 2;
         expected = tinv(0.975,dfe) / tinv(0.84,dfe);
         tol = 1e-6;

         returned = (Fit95.bH - Fit95.bL) / (Fit68.bH - Fit68.bL);

         testCase.verifyEqual(returned,expected,'RelTol',tol)
      end

      function test_nlsHonorsMask(testCase)
         % A masked fit equals the fit of the points the mask keeps.
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         q = q .* (1 + 0.2*sin((1:numel(q))'));
         mask = mod((1:numel(q))',5) ~= 0;
         FitSubset = baseflow.fitab(q(mask),dqdt(mask),'nls');
         expected = FitSubset.ab;

         FitMasked = baseflow.fitab(q,dqdt,'nls','mask',mask);
         returned = FitMasked.ab;

         testCase.verifyEqual(returned,expected)
      end

      function test_fixedSlopeDefaultsToOne(testCase,FixedSlopeMethod)
         % A fixed-slope method with no 'order' fits a line of slope 1, so
         % b = 1. Then log a is the center of log -dq/dt minus the center
         % of log q. The center is the mean for 'mean', and the median for
         % 'median' and for 'envelope' at its default refqtls [0.5 0.5].
         % An odd number of points makes each median one of the points.
         [~,q,dqdt] = baseflow.generateTestData(1e-2,1.5,100,1:101);
         if strcmp(FixedSlopeMethod,'mean')
            center = @mean;
         else
            center = @median;
         end
         expected = [exp(center(log(-dqdt)) - center(log(q))); 1];
         tol = 1e-12;

         returned = baseflow.fitab(q,dqdt,FixedSlopeMethod);

         testCase.verifyEqual(returned.ab,expected,'RelTol',tol)
      end
   end
end
