%% Power-law notation across plfit, r_plfit, gpd, and baseflow
% This page maps the exponent conventions of the four power-law estimators
% that the toolbox works with. It states how each estimator imposes lower
% and upper cutoffs, and it runs a worked comparison on one synthetic
% dataset. It resolves a long-standing notation confusion. The mappings
% were checked against the r_plfit code, the Hanel appendices, and a
% transcription of the Kondlo thesis.
%
%% Reference convention: the pdf exponent A
% Let A denote the exponent of the probability density,
%
% $$p(x) \propto x^{-A}, \quad x \ge x_{min}.$$
%
% Every quantity below is a function of A:
%
% * Clauset's |alpha| (deps/plfit.m) *is* A. The MLE is
%   |alpha = 1 + n/sum(log(x/xmin))|.
% * Hanel's sample-mode |lambda| (r_plfit) *is* A. It needs no
%   transformation. Hanel claims that the method "works for all
%   exponents", including lambda <= 1. The claim holds because a finite
%   upper cutoff x_max normalizes p(x) when the infinite-support integral
%   diverges. This explanation resolves the notation confusion. The sign
%   convention matches Clauset.
% * The ccdf (survival) exponent is A-1: |ccdf = (xmin/x)^(A-1)|. This
%   identity and the generalized Pareto mapping below hold for the
%   unbounded Pareto tail with A > 1. A <= 1 requires a finite upper
%   cutoff x_max. With x_max, the survival function uses the truncated
%   normalization instead, with a logarithmic form at A = 1.
%   Kondlo's |a| is the ccdf exponent, so |alpha = a+1|.
% * The MATLAB generalized Pareto shape is |k = 1/(A-1)|, with
%   threshold |theta = xmin| and scale |sigma = xmin/(A-1) = k*xmin| for
%   an exact unbounded Pareto tail (A > 1). |sigma/k = xmin| is the
%   population identity. gpfitb's |tau0 = sigma/k| is therefore a
%   consistent estimate of xmin from the independently fitted sigma and
%   k. It does not recover xmin exactly in a finite sample.
%   Confidence-interval propagation for tau0 is still a to-do in gpfitb.m.
% * baseflow's recession exponent is |b = 1 + 1/A|, so
%   |A = 1/(b-1)|, |k = (1-b)/(b-2)|, and |b = (2k+1)/(k+1)|
%   (conversions.m, plfitb.m).
% * Hanel's histogram-as-data mode 3 fits the *frequency distribution*
%   of a sample whose pdf exponent is lambda. That frequency exponent is
%   |1 + 1/lambda|. It is a different exponent, not a different
%   convention for the same exponent.
%
% Earlier scratch code contains three lambda-alpha relations. Each one is
% correct in its own context. The three relations apply to three different
% exponents that the scratch code wrote with one symbol:
%
% * |alpha = lambda + 1| (demo_rplfit candidate): correct when lambda
%   names the *ccdf* exponent (Kondlo's a).
% * |alpha = 1 + 1/lambda| (pllambda2alpha): correct for Hanel's
%   *mode-3 frequency* exponent and for the rank-size (Zipf) duality.
% * |lambda = 1/(alpha - 1)| (plalpha2lambda): the inverse of the
%   previous relation; this lambda equals the gpd shape k.
%
% Hanel's sample-mode lambda needs none of these relations because it is A
% itself. An edited r_plfit copy that sets |out.b = 1 + 1/Aml| is therefore
% correct (see the README r_plfit note).
%
%% Cutoffs by method
% * *Clauset plfit*: estimates the lower cutoff xmin by scanning unique
%   values for the minimum KS distance. It has no upper cutoff.
% * *MATLAB gpd* (gpfitb): the user supplies the threshold (xmin), and
%   the fit subtracts it. It has no upper cutoff.
% * *Hanel r_plfit*: |rangemin| is an input that the code echoes back
%   and never estimates (plfitb's 'hanel' method passes in Clauset's
%   xmin). An explicit |rangemax| pre-truncates the support. In the
%   default discrete mode, an automatic low-frequency cutoff re-solves
%   the MLE iteratively on a trimmed support. The result is a
%   doubly-truncated power-law MLE. Continuous data need the |'cdat'|
%   flag. Without it, the code bins real values on the integer grid
%   min(x):max(x). |'cdat'| also disables the automatic cutoff, so only
%   |rangemin|, |rangemax|, or the sample extremes truncate a continuous
%   fit. The search bounds are |'exp_min'| and |'exp_max'|. The help
%   text names them |'alpha_min'|/|'alpha_max'|, but the parser accepts
%   only the |exp_*| names and skips unknown options without an
%   error.
% * *Kondlo MLE* (Kondlo, 2010; not part of the toolbox): the full
%   doubly-truncated estimator. It jointly estimates the exponent, both
%   cutoffs L and U, and a Gaussian measurement-error sigma. It
%   maximizes the likelihood of the truncated Pareto convolved with
%   N(0, sigma^2). It accepts continuous data only, assumes homoskedastic
%   Gaussian error, and requires a > 0 (so A > 1). It fits the whole
%   sample rather than the tail only. U is weakly identified when the
%   sample misses the upper tail.
%
%% Worked comparison on one synthetic sample
% Draw a Pareto sample with a known pdf exponent. Then fit it four ways.

% known truth: pdf exponent A = 2.5, so b = 1.4, k = 2/3, ccdf a = 1.5
A = 2.5;
xmin = 1;
N = 5000;
rng(42, 'twister');
u = rand(N, 1);
x = xmin*(1 - u).^(-1/(A - 1));

% Clauset plfit: alpha estimates A directly
[alphaClauset, xminClauset] = baseflow.deps.plfit(x);
fprintf('Clauset  alpha = %.3f (xmin = %.3f)\n', alphaClauset, xminClauset)

% MATLAB gpd on the exceedances over the known threshold: A = 1 + 1/k
parmhat = gpfit(x(x > xmin) - xmin);
fprintf('gpd      alpha = %.3f (k = %.3f)\n', 1 + 1/parmhat(1), parmhat(1))

% baseflow plfitb: b converts back to A = 1/(b-1)
Fit = baseflow.plfitb(x);
fprintf('plfitb   alpha = %.3f (b = %.3f, tau0 = %.3f)\n', ...
   1/(Fit.b - 1), Fit.b, Fit.tau0)

% Hanel r_plfit (external; see the README r_plfit note): sample-mode
% lambda estimates A directly. 'cdat' declares continuous data.
if exist('r_plfit', 'file') == 2
   alphaHanel = r_plfit(x, 'rangemin', xminClauset, ...
      'exp_min', 1.5, 'exp_max', 3.5, 'cdat');
   fprintf('r_plfit  alpha = %.3f\n', alphaHanel)
else
   fprintf('r_plfit  not on the path; see the README r_plfit note\n')
end

% the estimates agree with the truth within sampling error
assert(abs(alphaClauset - A) < 0.15)
assert(abs(1 + 1/parmhat(1) - A) < 0.15)
assert(abs(1/(Fit.b - 1) - A) < 0.15)
