classdef test_yorkfit < matlab.unittest.TestCase
   %TEST_YORKFIT Test the York bivariate regression helper.
   %
   % yorkfit is private, so the tests reach it with baseflow.privatefunction.
   % One test checks the iterative York solution against published values
   % for the Pearson (1901) data with York (1966) weights. Other tests use
   % hand-computed values for each input branch: the two ordinary
   % least-squares short circuits, the four-input zero correlation default,
   % the unit-weight major-axis case, and the input validation errors.

   properties (TestParameter)
      % Sizes of the x and y vectors for the zero-error OLS short circuit.
      % Row vectors take the short circuit like columns.
      orientation = struct('column', [4, 1], 'row', [1, 4])

      % Sigma vector pairs for x = (1:6)' in the omitted-rxy test. Constant
      % sigma vectors have no defined correlation with each other.
      % Proportional sigma vectors correlate perfectly across points. That
      % is not an error correlation, so an omitted rxy must still equal an
      % explicit zero rxy.
      sigmapair = struct( ...
         'constant', {{0.5*ones(6, 1), 0.2*ones(6, 1)}}, ...
         'proportional', {{0.1*(1:6)', 0.2*(1:6)'}})

      % Invalid inputs. Each case holds the position of one of the valid
      % inputs, the invalid value that replaces it, and the expected error
      % identifier: X contains NaN, X and Y have different sizes, sigX is
      % not finite, sigY contains NaN, and rxy contains NaN.
      badinput = struct( ...
         'xNaN', {{1, [1; NaN; 3], 'MATLAB:yorkfit:expectedNonNaN'}}, ...
         'ySize', {{2, [2; 4], 'MATLAB:yorkfit:incorrectSize'}}, ...
         'sigxInf', {{3, [0.1; Inf; 0.1], ...
         'MATLAB:yorkfit:expectedFinite'}}, ...
         'sigyNaN', {{4, [1; NaN; 3], 'MATLAB:yorkfit:expectedNonNaN'}}, ...
         'rxyNaN', {{5, NaN, 'MATLAB:yorkfit:expectedNonNaN'}})
   end

   properties (Constant)
      % Valid x, y, sigX, sigY, and rxy inputs for the input validation
      % tests. Each badinput case replaces one of them.
      validinputs = {[1; 2; 3], [2; 4; 7], [0.1; 0.1; 0.1], ...
         [0.1; 0.1; 0.1], 0}
   end

   properties
      % The private yorkfit function handle.
      yorkfit
   end

   methods (TestClassSetup)
      function getyorkfit(testCase)
         % Store the private function handle once for every test.
         testCase.yorkfit = baseflow.privatefunction('yorkfit');
      end
   end

   methods (Access = private)
      function [ab, stats, warnmsg] = runyorkfit(testCase, varargin)
         % Call yorkfit with the warning display off and return the message
         % of the last warning it raised. yorkfit raises warnings with no
         % identifier, so verifyWarning cannot match them. lastwarn records
         % the message when the display is off. The teardown restores the
         % warning state if yorkfit errors.
         warnstate = warning('off', 'all');
         testCase.addTeardown(@warning, warnstate)
         lastwarn('', '');
         [ab, stats] = testCase.yorkfit(varargin{:});
         warnmsg = lastwarn;
         warning(warnstate)
      end
   end

   methods (Test)
      function test_pearsonYorkReference(testCase)
         % Pearson (1901) data with York (1966) weights and uncorrelated
         % errors. Reference: Cantrell (2008), Atmos. Chem. Phys. 8,
         % 5477-5487, Table 2, Williamson-York row: slope -0.48053 (std err
         % 0.0706) and intercept 5.4799 (std err 0.359). Cantrell Eq. 6
         % scales the York et al. (2004) sigma by sqrt(S/(n-2)), which is
         % the stats.a_std and stats.b_std definition. Each tolerance is
         % half of the last published digit.
         x = [0.0; 0.9; 1.8; 2.6; 3.3; 4.4; 5.2; 6.1; 6.5; 7.4];
         y = [5.9; 5.4; 4.4; 4.6; 3.5; 3.7; 2.8; 2.8; 2.4; 1.5];
         wx = [1000; 1000; 500; 800; 200; 80; 60; 20; 1.8; 1];
         wy = [1; 1.8; 4; 8; 20; 20; 70; 70; 100; 500];
         sigx = 1./sqrt(wx);
         sigy = 1./sqrt(wy);
         rxy = zeros(size(x));
         alpha = 0.05;

         b_expected = -0.48053;
         b_tol = 0.5e-5;
         a_expected = 5.4799;
         a_tol = 0.5e-4;
         b_std_expected = 0.0706;
         b_std_tol = 0.5e-4;
         a_std_expected = 0.359;
         a_std_tol = 0.5e-3;

         [ab_returned, stats_returned, warn_returned] = runyorkfit( ...
            testCase, x, y, sigx, sigy, rxy, alpha);

         % Six inputs with nonzero errors raise no warning.
         testCase.verifyEmpty(warn_returned)

         % Intercept and slope match the published York solution.
         ab_expected = [a_expected; b_expected];
         ab_tol = [a_tol; b_tol];
         testCase.verifyEqual(ab_returned, ab_expected, 'AbsTol', ab_tol)
         testCase.verifyEqual(stats_returned.a, a_expected, 'AbsTol', a_tol)
         testCase.verifyEqual(stats_returned.b, b_expected, 'AbsTol', b_tol)

         % Standard errors scaled by the goodness of fit match the reference.
         testCase.verifyEqual(stats_returned.a_std, a_std_expected, ...
            'AbsTol', a_std_tol)
         testCase.verifyEqual(stats_returned.b_std, b_std_expected, ...
            'AbsTol', b_std_tol)

         % Confidence bounds use the Student t critical value for n-2 = 8
         % degrees of freedom at two-sided alpha = 0.05: 2.306 in a t table.
         % The tolerance adds the rounding of each published factor.
         t_c_expected = 2.306;
         t_c_tol = 0.5e-3;
         a_ci_tol = a_tol + t_c_expected*a_std_tol + t_c_tol*a_std_expected;
         b_ci_tol = b_tol + t_c_expected*b_std_tol + t_c_tol*b_std_expected;
         a_L_expected = a_expected - t_c_expected*a_std_expected;
         a_H_expected = a_expected + t_c_expected*a_std_expected;
         b_L_expected = b_expected - t_c_expected*b_std_expected;
         b_H_expected = b_expected + t_c_expected*b_std_expected;
         testCase.verifyEqual(stats_returned.a_L, a_L_expected, ...
            'AbsTol', a_ci_tol)
         testCase.verifyEqual(stats_returned.a_H, a_H_expected, ...
            'AbsTol', a_ci_tol)
         testCase.verifyEqual(stats_returned.b_L, b_L_expected, ...
            'AbsTol', b_ci_tol)
         testCase.verifyEqual(stats_returned.b_H, b_H_expected, ...
            'AbsTol', b_ci_tol)

         % The x-intercept is -a/b. The tolerance propagates the a and b
         % rounding.
         xint_expected = -a_expected/b_expected;
         xint_tol = a_tol/abs(b_expected) ...
            + abs(a_expected)*b_tol/b_expected^2;
         testCase.verifyEqual(stats_returned.xintercept, xint_expected, ...
            'AbsTol', xint_tol)

         % The fitted values are affine in x with a nonzero slope, so the
         % squared correlation of y with yhat equals the squared correlation
         % of x with y.
         rsq_tol = 1e-12;
         dx = x - mean(x);
         dy = y - mean(y);
         rsq_expected = sum(dx.*dy)^2/(sum(dx.^2)*sum(dy.^2));
         testCase.verifyEqual(stats_returned.rsq, rsq_expected, ...
            'AbsTol', rsq_tol)
      end

      function test_exactLineFourInputs(testCase)
         % Points on the line y = 1 + 2x have zero residuals, so the York
         % fit returns the line for any weights. With zero residuals, York
         % et al. (2004) step 4 gives beta_i = U_i. The step 8 adjusted
         % points equal the data, sigma_b = 1/sqrt(sum(W U^2)), and
         % sigma_a = sqrt(1/sum(W) + Xbar^2 sigma_b^2). Four inputs set rxy
         % to zero. The x values are unsorted to test xfit.
         x = [2; 0; 3; 1];
         a_expected = 1;
         b_expected = 2;
         y = a_expected + b_expected*x;
         sigx = [1; 2; 1; 2];
         sigy = [1; 1; 2; 2];
         tol = 1e-10;
         warn_expected = 'error covariance set to zero';

         [ab_returned, stats_returned, warn_returned] = runyorkfit( ...
            testCase, x, y, sigx, sigy);

         % Four inputs warn that the error covariance is set to zero.
         testCase.verifyEqual(warn_returned, warn_expected)

         % The fit recovers the exact line.
         ab_expected = [a_expected; b_expected];
         testCase.verifyEqual(ab_returned, ab_expected, 'AbsTol', tol)

         % Hand-derived sigma values for rxy = 0 and exact data.
         wx = 1./sigx.^2;
         wy = 1./sigy.^2;
         W = wx.*wy./(wx + b_expected^2*wy);
         xbar = sum(W.*x)/sum(W);
         U = x - xbar;
         b_sig_expected = 1/sqrt(sum(W.*U.^2));
         a_sig_expected = sqrt(1/sum(W) + xbar^2*b_sig_expected^2);
         testCase.verifyEqual(stats_returned.b_sig, b_sig_expected, ...
            'AbsTol', tol)
         testCase.verifyEqual(stats_returned.a_sig, a_sig_expected, ...
            'AbsTol', tol)

         % Zero residuals make S, the scaled errors, and the interval
         % widths zero. The compared fields are S, Sbar, a_std, b_std, SSE,
         % and SE.
         zerostats_returned = [stats_returned.S, stats_returned.Sbar, ...
            stats_returned.a_std, stats_returned.b_std, ...
            stats_returned.SSE, stats_returned.SE];
         zerostats_expected = zeros(1, 6);
         testCase.verifyEqual(zerostats_returned, zerostats_expected, ...
            'AbsTol', tol)
         ci_returned = [stats_returned.a_L, stats_returned.a_H, ...
            stats_returned.b_L, stats_returned.b_H];
         ci_expected = [a_expected, a_expected, b_expected, b_expected];
         testCase.verifyEqual(ci_returned, ci_expected, 'AbsTol', tol)

         % For n-2 = 2 degrees of freedom the Student t CDF has the closed
         % form F(t) = 1/2 + t/(2 sqrt(2 + t^2)), so the two-sided p-value
         % is 1 - |t|/sqrt(2 + t^2).
         t_a = a_expected/a_sig_expected;
         t_b = b_expected/b_sig_expected;
         a_pval_expected = 1 - abs(t_a)/sqrt(2 + t_a^2);
         b_pval_expected = 1 - abs(t_b)/sqrt(2 + t_b^2);
         testCase.verifyEqual(stats_returned.a_pval, a_pval_expected, ...
            'AbsTol', tol)
         testCase.verifyEqual(stats_returned.b_pval, b_pval_expected, ...
            'AbsTol', tol)

         % Fitted, sorted, residual, and adjusted values follow from exact
         % data.
         resids_expected = zeros(size(x));
         testCase.verifyEqual(stats_returned.resids, resids_expected, ...
            'AbsTol', tol)
         yhat_expected = y;
         testCase.verifyEqual(stats_returned.yhat, yhat_expected, ...
            'AbsTol', tol)
         xfit_expected = [0; 1; 2; 3];
         testCase.verifyEqual(stats_returned.xfit, xfit_expected)
         yfit_expected = a_expected + b_expected*xfit_expected;
         testCase.verifyEqual(stats_returned.yfit, yfit_expected, ...
            'AbsTol', tol)
         xadj_expected = x;
         testCase.verifyEqual(stats_returned.xadj, xadj_expected, ...
            'AbsTol', tol)
         yadj_expected = y;
         testCase.verifyEqual(stats_returned.yadj, yadj_expected, ...
            'AbsTol', tol)
         rsq_expected = 1;
         testCase.verifyEqual(stats_returned.rsq, rsq_expected, ...
            'AbsTol', tol)
         xint_expected = -a_expected/b_expected;
         testCase.verifyEqual(stats_returned.xintercept, xint_expected, ...
            'AbsTol', tol)

         % The model description and function handle evaluate the same
         % line.
         func_expected = 'y=a+b*x';
         testCase.verifyEqual(stats_returned.func, func_expected)
         xeval = 5;
         fnc_expected = a_expected + b_expected*xeval;
         testCase.verifyEqual(stats_returned.fnc(xeval), fnc_expected, ...
            'AbsTol', tol)
      end

      function test_unitWeightsMajorAxis(testCase)
         % Scalar unit errors with four inputs set rxy to 0. York regression
         % with equal unit weights and zero correlation is major-axis
         % (orthogonal) regression:
         % b = (Syy - Sxx + sqrt((Syy - Sxx)^2 + 4 Sxy^2))/(2 Sxy).
         % For these data, hand-computed sums about the means (1.5, 2.5) are
         % Sxx = 5, Syy = 5, and Sxy = 4.
         x = [0; 1; 2; 3];
         y = [1; 3; 2; 4];
         sigx = 1;
         sigy = 1;
         Sxx = 5;
         Syy = 5;
         Sxy = 4;
         xmean = 1.5;
         ymean = 2.5;
         tol = 1e-12;
         warn_expected = 'error covariance set to zero';
         b_expected = (Syy - Sxx + sqrt((Syy - Sxx)^2 + 4*Sxy^2))/(2*Sxy);
         a_expected = ymean - b_expected*xmean;

         [ab_returned, ~, warn_returned] = runyorkfit(testCase, x, y, ...
            sigx, sigy);

         testCase.verifyEqual(warn_returned, warn_expected)
         ab_expected = [a_expected; b_expected];
         testCase.verifyEqual(ab_returned, ab_expected, 'AbsTol', tol)
      end

      function test_zeroErrorsReturnOLS(testCase, orientation)
         % Zero errors in x and y short-circuit to ordinary least squares
         % with a warning, for column and row vectors. Hand-computed OLS for
         % these data: Sxy = 4, Sxx = 5, so b = 0.8 and
         % a = 2.5 - 0.8*1.5 = 1.3. stats holds only a and b.
         x = reshape([0, 1, 2, 3], orientation);
         y = reshape([1, 3, 2, 4], orientation);
         sigx = 0;
         sigy = 0;
         Sxx = 5;
         Sxy = 4;
         xmean = 1.5;
         ymean = 2.5;
         tol = 1e-12;
         warn_expected = ...
            'expected sigX and sigY to be non-zero; returning OLS solution';
         fields_expected = {'a'; 'b'};
         b_expected = Sxy/Sxx;
         a_expected = ymean - b_expected*xmean;

         [ab_returned, stats_returned, warn_returned] = runyorkfit( ...
            testCase, x, y, sigx, sigy);

         testCase.verifyEqual(warn_returned, warn_expected)
         ab_expected = [a_expected; b_expected];
         testCase.verifyEqual(ab_returned, ab_expected, 'AbsTol', tol)
         testCase.verifyEqual(fieldnames(stats_returned), fields_expected)
         testCase.verifyEqual(stats_returned.a, a_expected, 'AbsTol', tol)
         testCase.verifyEqual(stats_returned.b, b_expected, 'AbsTol', tol)
      end

      function test_omittedRxy(testCase, sigmapair)
         % Four inputs warn and return the same fit as five inputs with an
         % explicit zero rxy. The fnc field is a function handle, and two
         % handles from separate calls never compare equal, so the test
         % removes it.
         x = (1:6)';
         y = [1; 3; 2; 5; 4; 6];
         [sigx, sigy] = sigmapair{:};
         rxy = 0;
         warn_expected = 'error covariance set to zero';
         [ab_expected, stats_expected] = runyorkfit(testCase, x, y, ...
            sigx, sigy, rxy);
         stats_expected = rmfield(stats_expected, 'fnc');

         [ab_returned, stats_returned, warn_returned] = runyorkfit( ...
            testCase, x, y, sigx, sigy);

         testCase.verifyEqual(warn_returned, warn_expected)
         testCase.verifyEqual(ab_returned, ab_expected)
         testCase.verifyEqual(rmfield(stats_returned, 'fnc'), stats_expected)
      end

      function test_zeroWeightDenominatorReturnsOLS(testCase)
         % With rxy = 1, the York weight denominator is
         % wX + b^2 wY - 2 b sqrt(wX wY) = (sqrt(wX) - b sqrt(wY))^2. Two
         % points on y = x give the OLS slope b = 1 = sigY/sigX, so every
         % denominator is zero and yorkfit returns the OLS line without a
         % warning. Five inputs use the default alpha.
         x = [0; 1];
         y = [0; 1];
         sigx = 1;
         sigy = 1;
         rxy = 1;
         a_expected = 0;
         b_expected = 1;
         fields_expected = {'a'; 'b'};

         [ab_returned, stats_returned, warn_returned] = runyorkfit( ...
            testCase, x, y, sigx, sigy, rxy);

         testCase.verifyEmpty(warn_returned)
         ab_expected = [a_expected; b_expected];
         testCase.verifyEqual(ab_returned, ab_expected)
         testCase.verifyEqual(fieldnames(stats_returned), fields_expected)
      end

      function test_tooFewInputs(testCase)
         % Fewer than four inputs raise the narginchk error.
         args = testCase.validinputs(1:3);
         errid = 'MATLAB:narginchk:notEnoughInputs';
         testCase.verifyError(@() testCase.yorkfit(args{:}), errid)
      end

      function test_invalidInput(testCase, badinput)
         % Each case makes one input invalid and keeps the other inputs
         % valid.
         [position, value, errid] = badinput{:};
         args = testCase.validinputs;
         args{position} = value;
         testCase.verifyError(@() testCase.yorkfit(args{:}), errid)
      end
   end
end
