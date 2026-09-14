function [ab, stats] = yorkfit(X,Y,sigX,sigY,rxy,alpha)
%YORKFIT bivariate estimator with correlated errors in X and Y
%     
% Reference: 
% D. York, N. Evensen, M. Martinez, J. Delgado "Unified equations for the 
% slope, intercept, and standard errors of the best straight line" Am. J.
% Phys. 72 (3) March 2004.
% 
% Matt Cooper, guycooper@ucla.edu
% 
% Inputs:
%   X       = observed data points (x-axis values)
%   Y       = observed data points (y-axis values)
%   sigX    = errors in the x-values
%   sigY    = errors in the y-values
%   rxy     = correlation between errors in the x-y values (0 if omitted)
%   alpha   = significance level for fitted error statistics (default 0.05)
%
% Intermediate values:
%   wX      = weights of x-values (1/sigX^2)
%   wY      = weights of y-values (1/sigY^2)
%   ai      = sqrt(wX.*wY), geometric mean of the weights
%   ripai   = rxy times ai, for faster computation
%   riqai   = ri divided by ai, for faster computation
%   Wi      = least squares term
%   x       = least-squares adjusted data points (x-axis values)
%   y       = least-squares adjusted data points (y-axis values)
%
% Outputs:
%   ab      = [a; b], y-intercept a and slope b
%   stats   = struct with a, b, standard errors, confidence bounds,
%             p-values, fitted values, and residuals. When sigX and sigY
%             are both zero, or every York weight denominator is zero,
%             yorkfit returns the ordinary least-squares fit and stats
%             holds only a and b.


%% INPUT CHECKS

% must be 4-6 inputs
narginchk(4,6)
N = numel(X);

% confirm X, Y, sigX, and sigY are valid numeric vectors (or scalars)
validateattributes(X, {'numeric'},{'real','vector','size',size(Y),    ...
   'nonempty','nonnan','finite'}, mfilename,'X',1)
validateattributes(Y, {'numeric'},{'real','vector','size',size(X),    ...
   'nonempty','nonnan','finite'}, mfilename,'Y',2)
validateattributes(sigX,{'numeric'},{'real','vector','nonempty',        ...
   'nonnan','finite'}, mfilename,'sigX',3)
validateattributes(sigY,{'numeric'},{'real','vector','nonempty',        ...
   'nonnan','finite'}, mfilename,'sigY',4)
% the X and Y checks do not include 'nonzero'; this should be OK

% convert inputs to columns before the OLS short circuit, which requires
% N-by-1 X and Y; validateattributes accepts row vectors
X   = X(:); Y = Y(:); sigX = sigX(:); sigY = sigY(:);

% if sigX and sigY are zero, short-circuit to ordinary least squares
if all(sigX == 0 & sigY == 0)
   [ab,stats]  = statsOLS(X,Y,N);
   warning('expected sigX and sigY to be non-zero; returning OLS solution');
   return
end

% if rxy is not given, set it to zero, as the warning states. corr(sigX,sigY)
% does not estimate rxy. It compares error sizes across points, not the x
% and y errors of one point, and it is nan for constant sigma vectors.
if nargin==4
   rxy = 0;
   warning('error covariance set to zero')
end

% assign 95% confidence level if not given
if nargin<=5; alpha = 0.05; end

% now make everything the same size, and double check rxy
if numel(sigX)==1;  sigX    = sigX*ones(N,1);   end
if numel(sigY)==1;  sigY    = sigY*ones(N,1);   end
if numel(rxy)==1;   rxy     = rxy*ones(N,1);    end

validateattributes(rxy,{'numeric'},{'real','vector','nonempty','nonnan',...
   'finite'},'yorkfit', 'rxy', 5) % rxy can be zero

% convert rxy to a column to match the other inputs
rxy = rxy(:);


%% MAIN PROGRAM

M       = [ones(N,1),X]\Y;              % step 1, initial guess OLS
b       = M(2);                         % initial slope
wX      = 1./sigX.^2;                   % step 2
wY      = 1./sigY.^2;                   % step 2
ai      = sqrt(wX.*wY);                 % for step 3
ripai   = rxy.*ai;                      % product, for step 3
riqai   = rxy./ai;                      % quotient, for step 4

% step 3

% Parked design: a planned short circuit to reduced major axis. With zero
% rxy and unit weights, the York solution is the major axis, not the
% reduced major axis (see the major-axis note after step 9). The block is
% empty, so the iterative solution below computes this case.
if all(rxy==0)&&all(wX==1)&&all(wY==1)
end

% short circuit to ordinary linear least-squares
if all((wX+b.*b.*wY-2.*b.*ripai) == 0)
   [ab,stats]  = statsOLS(X,Y,N);
   return
end

% if not, proceed with iterative solution
tol     = 1e-15;                        % iteration settings
dif     = 2*tol;
iter    = 0;
maxiter = 1000;

while dif > tol && iter < maxiter
   iter    = iter+1;
   bi      = b;
   Wi      = wX.*wY./(wX+bi.*bi.*wY-2.*bi.*ripai);         % step 3
   sumWi   = sum(Wi);
   barX    = sum(Wi.*X)/sumWi;                             % step 4
   barY    = sum(Wi.*Y)/sumWi;
   Ui      = X(:)-barX;
   Vi      = Y(:)-barY;
   beta    = Wi.*(Ui./wY+bi.*Vi./wX-(bi.*Ui+Vi).*riqai);
   Wibeta  = Wi.*beta;
   b       = sum(Wibeta.*Vi)/sum(Wibeta.*Ui);              % step 5
   dif     = abs(b-bi);                                    % step 6
end

% least-squares adjusted values (for standard errors)
a       = barY - b.*barX;                                   % step 7
xadj    = barX + beta;                                      % step 8
yadj    = barY + b.*beta;                                   % step 8
barx    = sum(Wi.*xadj)/sumWi;                              % step 9
u       = xadj - barx;
sigb    = sqrt(1/(sum(Wi.*u.*u)));
siga    = sqrt(1/(sumWi) + barx*barx*sigb*sigb);

% if all(rxy==0)&&all(wX.*wY./(wX+b.*b.*wY-2.*b.*ripai))
%    % this is major-axis, not sure if it can be short-circuited earlier
%    % might need to issue a warning that the supplied weights and
%    % correlation is equivalent to major axis which is invariant under
%    % a change in scale
% end

% standard errors and confidence intervals adjusted for sample size
% see sect. V.
resids  = Y-a-b.*X;
S       = sum(Wi.*resids.^2);
Sbar    = S/(N-2);                  % should be ~1 for gof
stda    = siga*sqrt(Sbar);
stdb    = sigb*sqrt(Sbar);
t_c     = tinv(1-alpha/2,N-2);
a_ci    = a+t_c*stda*[-1 1];
b_ci    = b+t_c*stdb*[-1 1];


% S       = sqrt(sum(Wi.*resids.^2)/(N-2));   % should = 1 if assumptions are valid
% stda    = siga*S;
% stdb    = sigb*S;


%% OUTPUT
ab              = [a;b];
stats.a         = a;
stats.b         = b;
stats.func      = 'y=a+b*x';
stats.fnc       = @(x)(a+b*x);
stats.a_sig     = siga;
stats.a_std     = stda;
stats.a_L       = a_ci(1);
stats.a_H       = a_ci(2);
stats.a_pval    = 2*(1-tcdf(abs(a/siga),N-2));
stats.b_sig     = sigb;
stats.b_std     = stdb;
stats.b_L       = b_ci(1);
stats.b_H       = b_ci(2);
stats.b_pval    = 2*(1-tcdf(abs(b/sigb),N-2));
stats.yhat      = a+b.*X;
stats.xfit      = sort(X);
stats.yfit      = a+b.*stats.xfit;
stats.resids    = resids;
stats.SSE       = sum(resids.*resids);
stats.SE        = sqrt(stats.SSE/(N-2));
stats.S         = S;
stats.Sbar      = Sbar;
stats.rsq       = corr(Y,stats.yhat,'Type','Pearson')^2;
stats.xadj      = xadj;
stats.yadj      = yadj;
stats.xintercept = -stats.a/stats.b;

% NOTE: PG 370 "in our work ... where the x-intercept is significant,
% we normally interchange x and y data to obtain the original
% x-intercept and its standard error". This is possible because yorkfit
% of y on x is symmetrical with x on y. stats.xintercept holds the
% x-intercept but not its standard error. For the standard error, use
% the interchange procedure quoted above.
end

function [ab,stats] = statsOLS(X,Y,N)
%STATSOLS Ordinary least-squares intercept and slope for yorkfit.
%
%  [ab, stats] = statsOLS(X, Y, N) returns ab = [a; b], the intercept and
%  slope of the ordinary least-squares fit of Y on X for N data points.
%  X and Y must be N-by-1 columns. stats contains only the fields a and b.
%
%  yorkfit calls statsOLS when sigX and sigY are both zero, or when every
%  York weight denominator is zero. In both cases the York solution
%  reduces to ordinary least squares.

% need to fill in the rest of the values for OLS

ab              = [ones(N,1),X]\Y;
stats.a         = ab(1);
% stats.a_sig     = siga;
% stats.a_std     = stda;
% stats.a_L       = a_ci(1);
% stats.a_H       = a_ci(2);
% stats.a_pval    = 2*(1-tcdf(abs(a/siga),N-2));
stats.b         = ab(2);
% stats.b_sig     = sigb;
% stats.b_std     = stdb;
% stats.b_L       = b_ci(1);
% stats.b_H       = b_ci(2);
% stats.b_pval    = 2*(1-tcdf(abs(b/sigb),N-2));
% stats.yhat      = a+b.*X;
% stats.xfit      = sort(X);
% stats.yfit      = a+b.*stats.xfit;
% stats.resids    = resids;
% stats.SSE       = sum(resids.*resids);
% stats.SE        = sqrt(stats.SSE/(N-2));
% stats.rsq       = corr(Y,stats.yhat,'Type','Pearson')^2;
%
end
