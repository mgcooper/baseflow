function [ab, stats] = yorkfit(X, Y, sigX, sigY, rxy, alpha)
   %YORKFIT Fit a straight line when both x and y carry measurement errors.
   %
   %  AB = YORKFIT(X, Y, SIGX, SIGY) fits Y = a + b*X to data whose X and Y
   %  values both carry known errors, and returns AB = [a; b]. The per-point
   %  error correlation is set to zero, with a warning.
   %
   %  AB = YORKFIT(X, Y, SIGX, SIGY, RXY) uses the per-point correlation RXY
   %  between the X error and the Y error of the same point.
   %
   %  AB = YORKFIT(X, Y, SIGX, SIGY, RXY, ALPHA) sets the significance level
   %  for the confidence bounds. ALPHA defaults to 0.05.
   %
   %  [AB, STATS] = YORKFIT(_) also returns the fit statistics listed under
   %  Outputs below.
   %
   %  Description
   %
   %  Ordinary least squares assumes the X values are exact. When they are not,
   %  its slope is biased, and collecting more data does not remove the bias.
   %  YORKFIT implements the York et al. (2004) solution, which weights each
   %  point by both of its errors and iterates to a slope consistent with those
   %  weights.
   %
   %  The direction of that bias depends on the errors. Under the classical
   %  assumptions, that the errors have zero mean, that both errors are
   %  uncorrelated with the true x, and that the x and y errors are uncorrelated
   %  with each other, the ordinary least-squares slope is biased toward zero by
   %  the factor var(x)/(var(x) + var(e)), where e is the x error. RXY admits
   %  correlated errors, and a nonzero cov(eX, eY) enters that limit as well, so
   %  the bias can then run either way.
   %
   %  Note: bias describes an estimator averaged over samples, not any one data
   %  set. Two estimates from one sample can differ in either direction, because
   %  they weight the same points differently. On the Pearson (1901) data of the
   %  example below, ordinary least squares returns the steeper slope of the
   %  two, -0.5396 against -0.4805.
   %
   %  Inputs
   %
   %    X      - observed x values, a numeric vector of N real finite values.
   %    Y      - observed y values, the same size as X.
   %    SIGX   - errors in X, a nonnegative scalar or an N-element vector.
   %             A scalar applies to every point.
   %    SIGY   - errors in Y, a nonnegative scalar or an N-element vector.
   %    RXY    - correlation between the X error and the Y error of the same
   %             point, a scalar or N-element vector within [-1 1]. Omitting
   %             RXY sets it to zero, which is the standard assumption when
   %             the correlation is unknown.
   %    ALPHA  - significance level for the confidence bounds, a scalar in
   %             (0, 1). Defaults to 0.05.
   %
   %  Outputs
   %
   %    AB     - [a; b], the intercept a and the slope b.
   %    STATS  - scalar struct. Every call returns the same fields in the
   %             same order, including the two ordinary least-squares short
   %             circuits described under Degenerate inputs. Four fields
   %             carry a different meaning on those two paths; see Statistics
   %             on the short circuits below.
   %
   %      a, b            intercept and slope, as in AB
   %      func, fnc       model description and a function handle for it
   %      a_sig, b_sig    standard errors implied by SIGX and SIGY
   %      a_std, b_std    standard errors scaled by the fit, see Error scaling
   %      a_L, a_H        confidence bounds on a at the level ALPHA
   %      b_L, b_H        confidence bounds on b at the level ALPHA
   %      a_pval, b_pval  two-sided p-values, computed from a_std and b_std
   %                      so they agree with the bounds above
   %      cov_ab          covariance of a and b. It pairs with the unscaled
   %                      a_sig and b_sig, not with a_std and b_std
   %      S               sum(Wi.*resids.^2), the York goodness-of-fit sum
   %      Sbar            S/(N-2), near 1 when SIGX and SIGY are right
   %      S_pval          upper-tail chi-square probability of S on N-2
   %                      degrees of freedom. A small value means the scatter
   %                      exceeds what the assigned errors predict
   %      resids          Y - a - b*X
   %      yhat            a + b*X
   %      xfit, yfit      sorted X and the line evaluated there, for plotting
   %      xadj, yadj      the adjusted data points of York step 8
   %      rsq             weighted squared correlation of Y with yhat
   %      SSE, SE         weighted error sum of squares and standard error
   %      xintercept      -a/b, or NaN when b is zero
   %      iter            iterations used
   %      converged       true when the slope met the tolerance below the
   %                      iteration limit
   %
   %  Error scaling
   %
   %  a_sig and b_sig are the York standard errors implied by SIGX and SIGY
   %  alone. a_std and b_std multiply them by sqrt(max(Sbar, 1)), which
   %  widens the interval when the scatter exceeds what the assigned errors
   %  predict and leaves it alone when the scatter is smaller. York Section V
   %  states that this scaling is not a mechanical step, so the multiplier
   %  never falls below 1: a fit better than the assigned errors predict does
   %  not license an interval narrower than those errors support. Use S_pval
   %  to judge whether the assigned errors are consistent with the data.
   %
   %  a_L, a_H, b_L, b_H, a_pval and b_pval all derive from a_std and b_std,
   %  so a p-value below ALPHA always means the matching interval excludes
   %  zero.
   %
   %  Statistics on the short circuits
   %
   %  Ordinary least squares has no assigned errors, so four fields describe
   %  something else on the two short-circuit paths.
   %
   %    a_sig, b_sig    the ordinary least-squares standard errors, taken
   %                    from the residual scatter rather than from SIGX and
   %                    SIGY. a_std equals a_sig and b_std equals b_sig
   %                    there, because there is no second quantity to scale
   %                    them by
   %    S, Sbar         the unweighted residual sum of squares and its mean
   %                    square, because the weights are 1. Sbar is therefore
   %                    the residual variance in the units of y squared, not
   %                    the dimensionless York ratio
   %    S_pval          NaN, because S follows a chi-square distribution only
   %                    when the weights are inverse variances
   %
   %  Degenerate inputs
   %
   %  SIGX(i) = 0 with nonzero SIGY(i) takes the York (2004) Appendix D limit Wi
   %  = wY(i), which is weighted least squares of y on x. The mirror case,
   %  SIGY(i) = 0 with nonzero SIGX(i), takes Wi = wX(i)/b^2. Both require
   %  RXY(i) = 0, because a zero-variance error has no defined correlation. A
   %  point whose SIGX and SIGY are both zero has no defined weight and raises
   %  an error. When every point has both errors zero, YORKFIT returns the
   %  ordinary least-squares fit with a warning.
   %
   %  Note: lscov solves those two limits exactly, and only those two. It
   %  takes a fixed weight matrix, so it cannot express a weight that depends
   %  on the slope, which is what makes the York problem iterative rather
   %  than linear. Refreshing the York weights and calling lscov again does
   %  not recover the York fit either: that loop drops the term in dS/db that
   %  comes from the weight itself. On the Pearson data of the example it
   %  converges to a slope of -0.4634 against the published -0.4805, at a
   %  larger S of 11.956 against 11.866.
   %
   %  Known bound on the mirror case: Wi = wX(i)/b^2 is unbounded at a zero
   %  slope, and YORKFIT then raises an error rather than taking the limit. A
   %  finite limit can exist there. For a constant Y beside one exact SIGY,
   %  replacing that zero by a small positive error and shrinking it converges
   %  on the horizontal line, which is what the error message asks the caller to
   %  do. Bead matfunclib-2td records why YORKFIT does not take that limit
   %  itself.
   %
   %  When every York weight denominator is zero, YORKFIT returns the ordinary
   %  least-squares fit. That denominator is wX + b^2*wY - 2*b*rxy*sqrt(wX*wY),
   %  which factors as the perfect square (sqrt(wX) - b*rxy*sqrt(wY))^2 only
   %  when rxy = +-1. Every denominator therefore vanishes together only for
   %  perfectly correlated errors that share one error ratio, at the slope
   %  sigY/(rxy*sigX).
   %
   %  N = 2 determines the line exactly, so the error statistics are undefined
   %  rather than unknown. YORKFIT returns a and b, sets every quantity derived
   %  from N-2 to NaN, and warns. The one exception is a singular weight: two
   %  points with RXY = +-1 can put the seed slope on the singular slope of one
   %  of them, and YORKFIT then raises the unbounded-weight error instead,
   %  because it never reaches the statistics.
   %
   %  b = 0 describes a horizontal line, which has no x-intercept, so xintercept
   %  is NaN and rsq is 0.
   %
   %  The weighted sum of squares can hold more than one local minimum, and the
   %  iteration stays in the basin of the slope it starts from. YORKFIT starts
   %  from the ordinary least-squares slope, which is the York (2004) step-1
   %  seed. It compares more than one starting slope only in the degenerate case
   %  where that seed leaves a weight unbounded. There it ranks a candidate that
   %  converged above one that reached the iteration limit, and compares S only
   %  between candidates whose convergence state matches. A candidate that hit
   %  the limit stopped at an arbitrary point of its cycle, so its S describes
   %  that point rather than a solution and can be the smaller of the two.
   %  converged reports that the tolerance was met, not that the minimum is the
   %  global one.
   %
   %  Unit weights with zero correlation give the major axis, not the reduced
   %  major axis. The major axis is not invariant under a change of scale. Use
   %  rmafit for the reduced major axis.
   %
   %  The x-intercept standard error
   %
   %  York (2004) page 370 states: "in our work ... where the x-intercept is
   %  significant, we normally interchange x and y data to obtain the original
   %  x-intercept and its standard error". This works because the York fit of y
   %  on x is symmetric with the fit of x on y. STATS.xintercept holds the
   %  x-intercept but not its standard error. For that error, call YORKFIT again
   %  with X and Y exchanged.
   %
   %  Examples
   %
   %    % Pearson (1901) data with York (1966) weights. Compare with York et
   %    % al. (2004) Table II: a = 5.4799, b = -0.4805, a_sig = 0.29497,
   %    % b_sig = 0.05799, Sbar = 1.48329.
   %    X = [0.0; 0.9; 1.8; 2.6; 3.3; 4.4; 5.2; 6.1; 6.5; 7.4];
   %    Y = [5.9; 5.4; 4.4; 4.6; 3.5; 3.7; 2.8; 2.8; 2.4; 1.5];
   %    sigX = 1./sqrt([1000; 1000; 500; 800; 200; 80; 60; 20; 1.8; 1]);
   %    sigY = 1./sqrt([1; 1.8; 4; 8; 20; 20; 70; 70; 100; 500]);
   %    [ab, stats] = yorkfit(X, Y, sigX, sigY, 0)
   %
   %    % Exact x values reduce the fit to weighted least squares of y on x.
   %    ab = yorkfit(X, Y, 0, sigY, 0)
   %
   %  References
   %
   %    York, D., N. M. Evensen, M. L. Martinez, and J. De Basabe Delgado
   %    (2004), Unified equations for the slope, intercept, and standard
   %    errors of the best straight line, Am. J. Phys., 72(3), 367-375.
   %
   %    Cantrell, C. A. (2008), Technical Note: Review of methods for linear
   %    least-squares fitting of data and application to atmospheric
   %    chemistry problems, Atmos. Chem. Phys., 8, 5477-5487.
   %
   %  See also: olsfit, pcafit, rmafit, gmrfit, lscov, defaultCurveData

   % Matt Cooper, guycooper@ucla.edu

   %% Input checks

   narginchk(4, 6)

   N = numel(X);

   % Confirm X, Y, sigX and sigY are valid numeric vectors (or scalars).
   % sigX and sigY must be nonnegative because yorkfit squares them to form
   % the weights, so a negative error would fit as though its absolute value
   % had been passed. The X and Y checks do not include 'nonzero'; this
   % should be OK.
   validateattributes(X, {'numeric'}, ...
      {'real', 'vector', 'size', size(Y), 'nonempty', 'nonnan', 'finite'}, ...
      mfilename, 'X', 1)
   validateattributes(Y, {'numeric'}, ...
      {'real', 'vector', 'size', size(X), 'nonempty', 'nonnan', 'finite'}, ...
      mfilename, 'Y', 2)
   validateattributes(sigX, {'numeric'}, ...
      {'real', 'vector', 'nonempty', 'nonnan', 'finite', 'nonnegative'}, ...
      mfilename, 'sigX', 3)
   validateattributes(sigY, {'numeric'}, ...
      {'real', 'vector', 'nonempty', 'nonnan', 'finite', 'nonnegative'}, ...
      mfilename, 'sigY', 4)

   % Convert inputs to columns before the OLS short circuit, which requires
   % N-by-1 X and Y. validateattributes accepts row vectors.
   X = X(:);
   Y = Y(:);

   % Expand sigX and sigY before the short circuit below. That short circuit
   % compares them elementwise, so a wrong length would fail there first, with a
   % message that names no argument.
   sigX = expandinput(sigX, N, 'sigX');
   sigY = expandinput(sigY, N, 'sigY');

   % Assign the 95% confidence level if not given. This precedes the short
   % circuit below because statsOLS reports confidence bounds too.
   if nargin <= 5
      alpha = 0.05;
   end
   validateattributes(alpha, {'numeric'}, ...
      {'real', 'scalar', '>', 0, '<', 1}, mfilename, 'alpha', 6)

   % Validate a supplied rxy before the short circuit below. That short circuit
   % returns, so validating afterwards would let an invalid rxy pass unreported
   % whenever every error happens to be zero. A correlation outside [-1 1] is
   % not a correlation, and rxy must be scalar or N-element like sigX and sigY.
   if nargin >= 5
      validateattributes(rxy, {'numeric'}, ...
         {'real', 'vector', 'nonempty', 'nonnan', 'finite', ...
         '>=', -1, '<=', 1}, mfilename, 'rxy', 5)
      rxy = expandinput(rxy, N, 'rxy');
   end

   % If sigX and sigY are zero, short circuit to ordinary least squares. This
   % precedes the rxy default so a four-input call on exact data raises one
   % warning rather than two.
   if all(sigX == 0 & sigY == 0)
      warning('matfunclib:yorkfit:zeroErrors', ...
         'expected sigX and sigY to be non-zero; returning OLS solution')
      [ab, stats] = statsOLS(X, Y, N, alpha);
      return
   end

   % If rxy is not given, set it to zero, as the warning states.
   % corr(sigX, sigY) does not estimate rxy. It compares error sizes across
   % points, not the x and y errors of one point, and it is NaN for constant
   % error vectors.
   if nargin == 4
      rxy = zeros(N, 1);
      warning('matfunclib:yorkfit:defaultErrorCorrelation', ...
         'error covariance set to zero')
   end

   % A zero-variance error has no defined correlation with anything, and a
   % point whose x and y are both exact has no defined weight.
   zeroX = sigX == 0;
   zeroY = sigY == 0;
   if any(zeroX & zeroY)
      error('matfunclib:yorkfit:bothErrorsZero', ...
         ['sigX and sigY are both zero at point(s) %s, which leaves the ' ...
         'York weight undefined. Remove those points, or assign a ' ...
         'nonzero error on one of the two axes.'], ...
         mat2str(find(zeroX & zeroY)'))
   end
   if any((zeroX | zeroY) & rxy ~= 0)
      error('matfunclib:yorkfit:correlatedZeroError', ...
         ['rxy is nonzero at point(s) %s, where sigX or sigY is zero. A ' ...
         'zero-variance error has no defined correlation. Set rxy to ' ...
         'zero at those points.'], ...
         mat2str(find((zeroX | zeroY) & rxy ~= 0)'))
   end

   %% Main program

   M = [ones(N, 1), X] \ Y;      % step 1, initial guess from OLS
   b = M(2);                     % initial slope
   wX = 1 ./ sigX.^2;            % step 2, weight of each x value
   wY = 1 ./ sigY.^2;            % step 2, weight of each y value

   % yorksums divides the step-3 weight by wX or by wY, whichever leaves the
   % smaller error ratio, so the denominator stays near 1 instead of growing
   % as 1/sigma^2. The York (2004) Appendix D limits then fall out of
   % ratioXY = 0 and ratioYX = 0 without a substitution.
   ratioXY = sigX ./ sigY;       % sqrt(wY/wX), zero where sigX is zero
   ratioYX = sigY ./ sigX;       % sqrt(wX/wY), zero where sigY is zero
   useXY = ratioXY <= 1;         % pick the form with the smaller ratio

   % An exact y value makes its step-3 weight proportional to 1/b^2, so a seed
   % at or near zero leaves it unbounded. Reseed from the ratio of the spreads.
   % That ratio has no sign, and the sign matters, because the weighted sum of
   % squares can hold two local minima and the iteration stays in the basin it
   % starts in. Try both signs and rank the results.
   seeds = b;
   if any(sigY == 0)
      seeddenom = yorkdenom(b, rxy, ratioXY, ratioYX, useXY);
      seedweights = yorkweights(wX, wY, seeddenom, useXY);
      if ~all(isfinite(seedweights))
         spread = std(Y) / std(X);
         seeds = [spread, -spread];
      end
   end

   % Short circuit to ordinary least squares for perfectly correlated errors,
   % where the denominator is a perfect square that vanishes at one slope. Both
   % tests matter. Without the correlation test an exact y value at a zero slope
   % would take this branch, whose denominator is also zero, and get an
   % unweighted fit in place of the Appendix D mirror limit. Without exact zero
   % a merely small denominator would take it, and that fit is still well
   % defined.
   if all(abs(rxy) == 1) ...
         && all(yorkdenom(b, rxy, ratioXY, ratioYX, useXY) == 0)
      [ab, stats] = statsOLS(X, Y, N, alpha);
      return
   end

   % Otherwise iterate. The tolerance combines an absolute floor with a relative
   % term, so it stays meaningful for slopes far from 1, where 1e-15 absolute
   % lies below the representable spacing of b.
   abstol = 1e-15;
   reltol = 1e-14;
   maxiter = 1000;

   % Steps 3 to 9, run once per candidate seed. bestcandidate holds the
   % iteration, the ranking between candidates and the failure handling, so
   % the degenerate cases stay out of the sequence above.
   [a, b, iter, converged, best] = bestcandidate(seeds, X, Y, wX, wY, ...
      sigX, sigY, rxy, ratioXY, ratioYX, useXY, abstol, reltol, maxiter);

   % An empty result means every candidate reached the slope at which all the
   % denominators vanish, which is the short circuit above arrived at a step
   % later. The seed can miss that slope by one ulp.
   if isempty(best)
      [ab, stats] = statsOLS(X, Y, N, alpha);
      return
   end

   if ~converged
      warning('matfunclib:yorkfit:notConverged', ...
         ['yorkfit did not converge in %d iterations. Returning the last ' ...
         'iterate. Check sigX, sigY and rxy.'], maxiter)
   end

   Wi = best.Wi;
   xadj = best.xadj;
   yadj = best.yadj;
   barx = best.barx;
   siga = best.siga;
   sigb = best.sigb;

   %% Output

   fit.a = a;
   fit.b = b;
   fit.X = X;
   fit.Y = Y;
   fit.W = Wi;
   fit.a_sig = siga;
   fit.b_sig = sigb;
   fit.barx = barx;
   fit.alpha = alpha;
   fit.xadj = xadj;
   fit.yadj = yadj;
   fit.iter = iter;
   fit.converged = converged;
   fit.weighted = true;

   ab = [a; b];
   stats = packstats(fit);
end

function value = expandinput(value, N, name)
   %EXPANDINPUT Expand a scalar to N elements, or check an N-element vector.
   %
   %  VALUE = EXPANDINPUT(VALUE, N, NAME) returns an N-by-1 column. A scalar is
   %  repeated N times and an N-element vector is returned as a column. Any
   %  other length raises an error naming the argument, because MATLAB would
   %  otherwise broadcast it without a check, or fail inside the arithmetic with
   %  a message that names nothing.

   if isscalar(value)
      value = value * ones(N, 1);
   elseif numel(value) == N
      value = value(:);
   else
      error('matfunclib:yorkfit:inconsistentSize', ...
         '%s has %d elements. Expected 1 or %d, to match X and Y.', ...
         name, numel(value), N)
   end
end

function [a, b, iter, converged, best] = bestcandidate(seeds, X, Y, wX, ...
      wY, sigX, sigY, rxy, ratioXY, ratioYX, useXY, abstol, reltol, maxiter)
   %BESTCANDIDATE Fit from each candidate seed slope and keep the best one.
   %
   %  [a, b, ITER, CONVERGED, BEST] = BESTCANDIDATE(SEEDS, ...) runs the York
   %  iteration from each slope in SEEDS and returns the intercept, slope,
   %  iteration count, convergence flag and step 7 to 9 quantities of the one it
   %  ranks highest. SEEDS holds one slope in every case except the degenerate
   %  one yorkfit describes, so this normally runs once.
   %
   %  Ranking puts a candidate that converged above one that reached MAXITER,
   %  and compares the weighted sum of squares only between candidates that
   %  agree on convergence. A candidate that hit the limit stopped at an
   %  arbitrary point of its cycle, so its sum describes that point rather than
   %  a solution and can be the smaller of the two.
   %
   %  BEST is empty when every candidate reached the slope at which all the
   %  denominators vanish. That is the perfectly correlated case, and yorkfit
   %  answers it with ordinary least squares. Any other failure is raised.

   bestS = Inf;
   best = [];
   a = [];
   b = [];
   iter = 0;
   converged = false;

   % Track why the candidates failed, not just that they did. degenerate means
   % a candidate reached a slope where EVERY weight is unbounded, which is the
   % perfectly correlated case yorkfit answers with ordinary least squares.
   % badpoints names the points for the error message otherwise.
   degenerate = false;
   badpoints = [];

   for k = 1:numel(seeds)
      [bk, iterk, convk, unbounded] = yorkiterate(seeds(k), X, Y, wX, wY, ...
         sigX, sigY, rxy, ratioXY, ratioYX, useXY, abstol, reltol, maxiter);

      % A candidate that ran into an unbounded weight is disqualified, not the
      % whole fit: one seed can pass through such a slope while the other never
      % does. Record what kind of failure it was, at the slope where it
      % happened, so nothing downstream has to reconstruct that slope.
      if any(unbounded)
         % Every weight unbounded is the degenerate case only when the errors
         % are perfectly correlated, which is the one configuration where a
         % single slope zeroes every denominator. Weights that all went
         % non-finite for another reason, such as an exact y value at a zero
         % slope, are a failure to report rather than a line to substitute.
         degenerate = degenerate || (all(unbounded) && all(abs(rxy) == 1));
         if isempty(badpoints)
            badpoints = find(unbounded);
         end
         continue
      end

      [ak, Sk, fitk, unbounded] = yorkfinal(bk, X, Y, wX, wY, sigX, sigY, ...
         rxy, ratioXY, ratioYX, useXY);

      % the iteration can converge onto a singular slope, so check again here
      if any(unbounded)
         degenerate = degenerate || (all(unbounded) && all(abs(rxy) == 1));
         if isempty(badpoints)
            badpoints = find(unbounded);
         end
         continue
      end

      if ~isfinite(Sk)
         continue
      end
      if isempty(best)
         better = true;
      elseif convk ~= converged
         better = convk;
      else
         better = Sk < bestS;
      end
      if better
         bestS = Sk;
         a = ak;
         b = bk;
         iter = iterk;
         converged = convk;
         best = fitk;
      end
   end

   if ~isempty(best)
      return
   end

   % Every candidate failed. An empty best plus degenerate tells yorkfit to
   % answer with ordinary least squares. Anything else is reported.
   if degenerate
      return
   end

   if isempty(badpoints)
      error('matfunclib:yorkfit:noFiniteSolution', ...
         ['yorkfit found no finite solution from any starting slope. ' ...
         'Check sigX, sigY and rxy.'])
   end

   error('matfunclib:yorkfit:unboundedWeight', ...
      ['the York weight is not finite at point(s) %s, because the step-3 ' ...
      'denominator vanished there. Two inputs produce that: a zero sigY ' ...
      'with a slope at or near zero, and an rxy of +-1 with a slope at or ' ...
      'near sigY/sigX. For the first, assign a small nonzero sigY, which ' ...
      'converges on the same line. For the second, move rxy away from ' ...
      '+-1.'], mat2str(badpoints'))
end

function [b, iter, converged, unbounded] = yorkiterate(b, X, Y, wX, wY, ...
      sigX, sigY, rxy, ratioXY, ratioYX, useXY, abstol, reltol, maxiter)
   %YORKITERATE York (2004) steps 3 to 6, iterated from one seed slope.
   %
   %  [b, ITER, CONVERGED, UNBOUNDED] = YORKITERATE(b, ...) refines the slope
   %  b until two successive values agree to within max(ABSTOL, RELTOL*|b|), or
   %  until MAXITER iterations have run. CONVERGED reports which of the two
   %  ended the loop.
   %
   %  UNBOUNDED is the mask yorksums returned at the slope the loop stopped at.
   %  Any of it being true means the loop stopped because a weight was not
   %  finite, rather than for either reason above, and b is the slope where
   %  that happened. Returning the mask from the slope that produced it is what
   %  saves the caller from reconstructing that slope afterwards.
   %
   %  The weighted sum of squares can hold more than one local minimum, and
   %  this iteration stays in the basin of its seed. yorkfit therefore calls it
   %  once per candidate seed and ranks the results, preferring a candidate
   %  that converged over one that reached MAXITER.

   iter = 0;
   converged = false;
   unbounded = false(size(X));

   while ~converged && iter < maxiter
      iter = iter + 1;
      bi = b;

      % the loop needs only the weights and the centered data. sumWi, barX and
      % barY belong to the recompute at the converged slope.
      [Wi, ~, ~, ~, Ui, Vi, beta, unbounded] = ...
         yorksums(X, Y, wX, wY, sigX, sigY, rxy, ratioXY, ratioYX, useXY, bi);

      % stop at the slope where the weights went unbounded, and report it
      if any(unbounded)
         b = bi;
         return
      end

      Wibeta = Wi .* beta;
      b = sum(Wibeta .* Vi) / sum(Wibeta .* Ui);   % step 5
      dif = abs(b - bi);                           % step 6
      converged = dif <= max(abstol, reltol * abs(b));
   end
end

function [a, S, fit, unbounded] = yorkfinal(b, X, Y, wX, wY, sigX, sigY, rxy, ...
      ratioXY, ratioYX, useXY)
   %YORKFINAL York (2004) steps 7 to 9 at the final slope.
   %
   %  [a, S, FIT] = YORKFINAL(b, ...) returns the intercept a, the weighted sum
   %  of squares S, and a struct FIT holding the weights Wi, the adjusted points
   %  xadj and yadj, their weighted mean barx, and the standard errors siga and
   %  sigb.
   %
   %  yorkiterate leaves its step-3 and step-4 quantities at the slope before
   %  its last update, so every quantity here is recomputed at b. Reusing the
   %  loop's values would mix the final slope with stale weights. yorkfit calls
   %  this on whatever slope the iteration ended on, including the last iterate
   %  when the iteration hit its limit. yorkfit also compares S across candidate
   %  seeds, which is why this returns it.

   [Wi, sumWi, barX, barY, ~, ~, beta, unbounded] = ...
      yorksums(X, Y, wX, wY, sigX, sigY, rxy, ratioXY, ratioYX, useXY, b);

   % The iteration can converge onto a singular slope, so this can be reached
   % with a mask the caller has not seen. Report it the same way yorksums
   % does and let bestcandidate decide, rather than asserting here.
   if any(unbounded)
      a = [];
      S = Inf;
      fit = [];
      return
   end

   a = barY - b .* barX;                     % step 7
   fit.Wi = Wi;
   fit.xadj = barX + beta;                   % step 8, adjusted x values
   fit.yadj = barY + b .* beta;              % step 8, adjusted y values
   fit.barx = sum(Wi .* fit.xadj) / sumWi;   % step 9
   u = fit.xadj - fit.barx;
   fit.sigb = sqrt(1 / sum(Wi .* u .* u));
   fit.siga = sqrt(1 / sumWi + fit.barx * fit.barx * fit.sigb * fit.sigb);

   % the goodness-of-fit sum at this slope, used to rank candidate seeds
   S = sum(Wi .* (Y - a - b .* X).^2);
end

function [denom, root, scale] = yorkdenom(b, rxy, ratioXY, ratioYX, useXY)
   %YORKDENOM York (2004) step-3 weight denominator, per point.
   %
   %  [DENOM, ROOT, SCALE] = YORKDENOM(b, rxy, ratioXY, ratioYX, useXY) returns
   %  the denominator of the York weight at the slope b, divided by wX where
   %  useXY is true and by wY elsewhere. ratioXY is sigX./sigY and ratioYX is
   %  its reciprocal. ROOT is the term the denominator squares, and SCALE is the
   %  size of the quantities that formed it, so a caller can ask whether ROOT is
   %  zero to within rounding. At rxy = +-1 the second term vanishes and DENOM
   %  is exactly ROOT^2.
   %
   %  York writes the weight as wX*wY/(wX + b^2*wY - 2*b*r_i*alpha_i) with
   %  alpha_i = sqrt(wX*wY). Dividing that denominator by wX leaves
   %  1 + b^2*ratioXY^2 - 2*b*r*ratioXY, and dividing it by wY instead leaves
   %  ratioYX^2 + b^2 - 2*b*r*ratioYX. Both are exact, and neither forms the
   %  product wX*wY, which overflows for very small errors.
   %
   %  yorkfit tests this for the zero-denominator short circuit and yorksums
   %  divides by it, so the expression is written once.

   % Write each denominator as a sum of two squares, not as an expanded
   % quadratic. The forms are algebraically identical:
   %   1 + b^2*q^2 - 2*b*r*q  =  (1 - b*r*q)^2 + b^2*q^2*(1 - r^2)
   %   q^2 + b^2 - 2*b*r*q    =  (q - b*r)^2   + b^2*(1 - r^2)
   % and |rxy| <= 1, so the right-hand sides cannot go negative. The
   % expanded forms can, through cancellation near the singular slope, and a
   % negative denominator gives complex standard errors with nothing
   % raised.
   denom = zeros(size(ratioXY));
   root = zeros(size(ratioXY));
   scale = zeros(size(ratioXY));
   spread = 1 - rxy .* rxy;

   % Form b*q before squaring it, because squaring b alone overflows for a
   % slope past about 1.3e154.
   qXY = ratioXY(useXY);
   rXY = rxy(useXY);
   bqXY = b .* qXY;
   root(useXY) = 1 - rXY .* bqXY;
   scale(useXY) = max(1, abs(rXY .* bqXY));
   denom(useXY) = root(useXY).^2 + bqXY .* bqXY .* spread(useXY);

   qYX = ratioYX(~useXY);
   rYX = rxy(~useXY);
   root(~useXY) = qYX - b .* rYX;
   scale(~useXY) = max(abs(qYX), abs(b .* rYX));
   denom(~useXY) = root(~useXY).^2 + b .* b .* spread(~useXY);
end

function Wi = yorkweights(wX, wY, denom, useXY)
   %YORKWEIGHTS York (2004) step-3 weights from a precomputed denominator.
   %
   %  Wi = YORKWEIGHTS(wX, wY, DENOM, useXY) multiplies the reduced denominator
   %  DENOM from yorkdenom back by the weight it was divided by: wY where useXY
   %  is true, and wX elsewhere.
   %
   %  The York (2004) Appendix D limits follow without a substitution. An exact
   %  x value gives ratioXY = 0, so DENOM is 1 and Wi reduces to wY, which is
   %  weighted least squares of y on x. An exact y value gives ratioYX = 0, so
   %  DENOM is b^2 and Wi reduces to wX/b^2.
   %
   %  yorkfit calls this once on its seed slope to check that the weights are
   %  finite before iterating, and yorksums calls it on every iteration.

   Wi = zeros(size(denom));
   Wi(useXY) = wY(useXY) ./ denom(useXY);
   Wi(~useXY) = wX(~useXY) ./ denom(~useXY);
end

function [Wi, sumWi, barX, barY, Ui, Vi, beta, unbounded] = yorksums( ...
      X, Y, wX, wY, sigX, sigY, rxy, ratioXY, ratioYX, useXY, b)
   %YORKSUMS York (2004) step-3 and step-4 quantities at one slope.
   %
   %  [Wi, sumWi, barX, barY, Ui, Vi, beta] = YORKSUMS(X, Y, wX, wY, sigX, sigY,
   %  rxy, ratioXY, ratioYX, useXY, b) returns the York weights Wi, their sum
   %  sumWi, the weighted means barX and barY, the centered data Ui and Vi, and
   %  the step-4 beta, all evaluated at the slope b. ratioXY is sigX./sigY,
   %  ratioYX is its reciprocal, and useXY marks the points whose weight is
   %  formed from wY rather than wX.
   %
   %  yorkfit calls this from inside the iteration and again at the converged
   %  slope, so the arithmetic is written once.

   % Step 3.
   denom = yorkdenom(b, rxy, ratioXY, ratioYX, useXY);
   Wi = yorkweights(wX, wY, denom, useXY);

   % A vanishing denominator makes Wi infinite, which would propagate NaN
   % through the weighted means below. Report which points that happened at
   % and return, rather than raising here.
   %
   % The mask carries everything the caller needs. any(unbounded) says the
   % slope is unusable, all(unbounded) says every point is singular at once,
   % and find(unbounded) names the points for the message. Deciding that here,
   % at the slope where it happened, is what keeps the caller from
   % reconstructing the slope afterwards and asking about a neighbouring one.
   %
   % all(unbounded) alone does not identify the case yorkfit answers with
   % ordinary least squares. Every sigY zero at a zero slope also sets it, and
   % that is a failure to report. bestcandidate therefore requires perfectly
   % correlated errors as well, which is the one configuration where a single
   % slope zeroes every denominator.
   unbounded = ~isfinite(Wi);
   if any(unbounded)
      sumWi = NaN;
      barX = NaN;
      barY = NaN;
      Ui = [];
      Vi = [];
      beta = [];
      return
   end

   sumWi = sum(Wi);
   barX = sum(Wi .* X) / sumWi;  % step 4
   barY = sum(Wi .* Y) / sumWi;
   Ui = X - barX;
   Vi = Y - barY;
   % Step 4, grouped by Ui and Vi. York writes
   % beta = Wi*(Ui/wY + b*Vi/wX - (b*Ui + Vi)*r/alpha); substituting
   % 1/wY = sigY^2, 1/wX = sigX^2 and r/alpha = r*sigX*sigY and collecting
   % gives the identical form below. The three-term version carries the same
   % cancellation as the denominator and loses the sign of beta near the
   % singular slope. It also divides by an infinite weight when an error is
   % zero.
   beta = Wi .* (Ui .* sigY .* (sigY - b .* rxy .* sigX) ...
      + Vi .* sigX .* (b .* sigX - rxy .* sigY));
end

function [ab, stats] = statsOLS(X, Y, N, alpha)
   %STATSOLS Ordinary least-squares intercept and slope for yorkfit.
   %
   %  [AB, STATS] = STATSOLS(X, Y, N, ALPHA) returns AB = [a; b], the intercept
   %  and slope of the ordinary least-squares fit of Y on X for N data points,
   %  together with the same STATS fields the iterative path returns. X and Y
   %  must be N-by-1 columns.
   %
   %  yorkfit calls statsOLS when sigX and sigY are both zero, and when every
   %  York weight denominator is zero. In both cases the York solution reduces
   %  to ordinary least squares.
   %
   %  Ordinary least squares has no assigned errors, so its standard errors come
   %  from the residual scatter alone. a_sig therefore equals a_std, and b_sig
   %  equals b_std, unlike the iterative path where the two differ by
   %  sqrt(max(Sbar, 1)). packstats reports S_pval as NaN here for the same
   %  reason: S follows a chi-square distribution only when the weights are
   %  inverse variances, and unit weights are not.

   ab = [ones(N, 1), X] \ Y;
   a = ab(1);
   b = ab(2);

   % Unit weights turn the York weighted sums into the ordinary ones, so
   % packstats computes S, Sbar, SSE, SE and rsq without a special case.
   W = ones(N, 1);
   xbar = mean(X);
   Sxx = sum((X - xbar).^2);

   % Two points determine the line exactly, so there is no residual variance
   % to estimate. The residuals are zero only up to roundoff, and a positive
   % roundoff sum divided by zero degrees of freedom would give Inf rather
   % than the NaN that packstats reports for every other n-2 quantity.
   if N > 2
      s2 = sum((Y - a - b .* X).^2) / (N - 2);
   else
      s2 = NaN;
   end

   fit.a = a;
   fit.b = b;
   fit.X = X;
   fit.Y = Y;
   fit.W = W;
   fit.a_sig = sqrt(s2 * (1 / N + xbar * xbar / Sxx));
   fit.b_sig = sqrt(s2 / Sxx);
   fit.barx = xbar;
   fit.alpha = alpha;

   % Ordinary least squares treats X as exact, so the adjusted points are
   % the observed X and the fitted Y.
   fit.xadj = X;
   fit.yadj = a + b .* X;
   fit.iter = 0;
   fit.converged = true;
   fit.weighted = false;

   stats = packstats(fit);
end

function stats = packstats(fit)
   %PACKSTATS Assemble the yorkfit stats struct.
   %
   %  STATS = PACKSTATS(FIT) builds the output struct from the fields of FIT:
   %  a, b, X, Y, W, a_sig, b_sig, barx, alpha, xadj, yadj, iter, converged
   %  and weighted.
   %
   %  Both yorkfit paths call this, so every call returns the same fields in
   %  the same order. weighted is false on the ordinary least-squares path,
   %  where a_sig already carries the residual scatter and must not be scaled
   %  by it a second time, and where S is not a chi-square variate.

   a = fit.a;
   b = fit.b;
   X = fit.X;
   Y = fit.Y;
   W = fit.W;
   N = numel(X);
   resids = Y - a - b .* X;

   % York's goodness-of-fit sum. With the unit weights of the ordinary
   % least-squares path this is the residual sum of squares.
   S = sum(W .* resids.^2);

   % The N-2 degrees of freedom vanish at N = 2, where the line is determined
   % exactly and the error statistics are undefined rather than unknown. Return
   % a, b and the fitted values, and NaN everything derived from N-2.
   if N > 2
      Sbar = S / (N - 2);        % should be ~1 for goodness of fit
      t_c = tinv(1 - fit.alpha / 2, N - 2);
   else
      warning('matfunclib:yorkfit:zeroDegreesOfFreedom', ...
         ['%d points determine the line exactly, so the error statistics ' ...
         'are undefined. Returning a and b with NaN error statistics.'], N)
      Sbar = NaN;
      t_c = NaN;
   end

   % Standard errors and confidence intervals adjusted for sample size, see
   % sect. V. The multiplier never falls below 1, because a fit better than
   % the assigned errors predict does not license an interval narrower than
   % those errors support. The ordinary least-squares path is already scaled
   % by its own residuals, so it takes no second multiplier.
   % N = 2 needs its own branch because max(NaN, 1) returns 1, which would
   % leave a_std and b_std finite among the other NaN quantities.
   if ~fit.weighted
      scale = 1;
   elseif N > 2
      scale = sqrt(max(Sbar, 1));
   else
      scale = NaN;
   end
   stda = fit.a_sig * scale;
   stdb = fit.b_sig * scale;
   a_ci = a + t_c * stda * [-1 1];
   b_ci = b + t_c * stdb * [-1 1];

   % Weighted fit statistics, so they describe the fit that was performed.
   % rsq is the weighted squared correlation of Y with yhat.
   yhat = a + b .* X;

   % A squared correlation does not change when the weights or the data are
   % multiplied by a constant, so normalize both before forming the moments.
   % Unscaled, they overflow or underflow before the ratio is taken.
   Wn = W / max(W);
   sumW = sum(Wn);
   ybar = sum(Wn .* Y) / sumW;
   hbar = sum(Wn .* yhat) / sumW;
   dY = Y - ybar;
   dH = yhat - hbar;

   % Divide by the largest magnitude, with no floor of 1: a floor leaves
   % small data unscaled, and it then squares to zero. Guard only the
   % all-zero case, which the ssY and ssH test below reports as rsq = 0.
   scaleY = max(abs(dY));
   scaleH = max(abs(dH));
   if scaleY > 0
      dY = dY / scaleY;
   end
   if scaleH > 0
      dH = dH / scaleH;
   end
   ssY = sum(Wn .* dY .* dY);
   ssH = sum(Wn .* dH .* dH);

   % A horizontal line makes yhat constant, so ssH is zero and the
   % correlation is undefined. Report rsq = 0, because the fit explains none
   % of the variance in Y.
   if ssH > 0 && ssY > 0
      rsq = sum(Wn .* dY .* dH)^2 / (ssY * ssH);
   else
      rsq = 0;
   end

   stats.a = a;
   stats.b = b;
   stats.func = 'y=a+b*x';
   stats.fnc = @(x) (a + b * x);
   stats.a_sig = fit.a_sig;
   stats.a_std = stda;
   stats.a_L = a_ci(1);
   stats.a_H = a_ci(2);
   % upper tail, for the same reason as S_pval above
   stats.a_pval = 2 * tcdf(abs(a / stda), N - 2, 'upper');
   stats.b_sig = fit.b_sig;
   stats.b_std = stdb;
   stats.b_L = b_ci(1);
   stats.b_H = b_ci(2);
   stats.b_pval = 2 * tcdf(abs(b / stdb), N - 2, 'upper');
   stats.yhat = yhat;
   stats.xfit = sort(X);
   stats.yfit = a + b .* stats.xfit;
   stats.resids = resids;
   stats.SSE = S;
   stats.SE = sqrt(Sbar);
   stats.S = S;
   stats.Sbar = Sbar;

   % S follows a chi-square distribution on N-2 degrees of freedom only when
   % the weights are inverse variances, which the ordinary least-squares
   % path does not satisfy.
   % Use the upper-tail form. Subtracting a CDF near 1 from 1 rounds every
   % probability below about 1e-16 to zero, and a poor fit is where a caller
   % needs the value.
   if fit.weighted && N > 2
      stats.S_pval = chi2cdf(S, N - 2, 'upper');
   else
      stats.S_pval = NaN;
   end

   stats.cov_ab = -fit.barx * fit.b_sig * fit.b_sig;
   stats.rsq = rsq;
   stats.xadj = fit.xadj;
   stats.yadj = fit.yadj;

   % A horizontal line has no x-intercept.
   if b == 0
      stats.xintercept = NaN;
   else
      stats.xintercept = -a / b;
   end

   stats.iter = fit.iter;
   stats.converged = fit.converged;
end
