function [Fit,ok] = fitab(q,dqdt,method,varargin)
%FITAB fit event-scale recession equation -dq/dt = aQ^b
%
% Syntax
%
%     [Fit,ok] = fitab(q,dqdt,method,varargin)
%
% Description
%
%     [Fit,ok] = fitab(q,dqdt,method) fits event-scale recession equation
%     -dq/dt = aQ^b to estimate parameters a and b using the specified fitting
%     method. Valid methods are ordinary least squares (ols), non-linear least
%     squares (nls), quantile regression (qtl), mean difference ('mean'), median
%     difference ('median').
%
% Required inputs
%
%     q        vector double of discharge data (L T^-1)
%     dqdt     vector double of discharge rate of change (L T^-2)
%     method   char indicating the fitting method
%
% Optional inputs
%
%     weights  vector double of weights for the fitting algorithm
%     mask     vector logical mask to exclude values from fitting
%     order    scalar, exponent in -dq/dt = aQ^b
%     refqtls  2x1 double, x/y quantiles used if 'method' == 'envelope'
%     quantile scalar double, quantile used if 'method' == 'qtl' (quantile regression)
%     Nboot    scalar double, bootstrap sample size for quantile regression
%     plotfit  logical scalar indicating whether to make a plot or not
%     fitopts  struct containing fitting options (not currently implemented)
%
% Notes 
%     weights are set zero anywhere mask is false
% 
%     Use method 'envelope' to pass a line through an arbitrary x,y pair
%     (refpoints), specified in terms of the quantile of the x/y data
%     distributions. this method is similar to 'mean' or 'median', but allows
%     different ref points for the x/y values, for example the median of the x
%     values (0.50 quantile) and some other quantile of the y values. The
%     default (recommended) behavior is to keep the x-quantile = 0.5 and vary
%     the y-quantile to move the line up and down as desired to define an
%     "envelope"
% 
% See also prepfits
%
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

persistent inoctave
if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
end

% PARSE INPUTS
[weights, order, mask, qtl, refqtls, Nboot, alpha, plotfit] = parseinputs( ...
   q, dqdt, method, mfilename, varargin{:});

% PREP FITS
[x, y, logx, logy, weights, ok] = bfra.prepfits( ...
   q, dqdt, 'weights', weights, 'mask', mask);

% FAST EXIT
if ok == false
   Fit = nan; return;
end

% If method = 'ols' and 'order' = 1, use method 'mean' with a line of slope 1
if strcmp(method,'ols') && order == 1
   method = 'mean';
end

% SWITCH YARD
fselect = method;

switch method
   case 'ols'
      [ab,ci,ok] = fitOLS(logx,logy,weights,alpha,inoctave);
   case 'qtl'
      [ab,ci,ok] = fitQTL(logx,logy,weights,alpha,order,qtl,Nboot,inoctave);
   case 'mle'
      error('mle fitting not currently supported');
      % [ab,ci,ok] = fitMLE(logx,logy,weights,alpha,sigx,sigy,rxy);
   case 'nls'
      [ab,ci,ok,fselect] = fitNLS(x,y,logx,logy,weights,alpha,inoctave);
   case 'mean'
      [ab,ci,ok] = fitLIN(logx,logy,weights,alpha,order,inoctave);
   case 'median'
      [ab,ci,ok] = fitMED(logx,logy,weights,order,inoctave);
   case 'envelope'
      [ab,ci,ok] = fitENV(logx,logy,weights,order,refqtls,inoctave);
end

% EVALUATE THE FIT
[Fit,ok] = evalFit(ab,x,y,ci,ok);

if exist('fselect','var')
   Fit.fselect = fselect;
end

if plotfit == true
   Fit.h = bfra.pointcloudplot(q,dqdt,'reflines',{'userfit'}, ...
      'userab',ab,'mask',mask,'usertext',method);
end


% FITTING METHODS
function [ab,ci,ok] = fitOLS(logx,logy,weights,alpha,inoctave)
% ordinary least squares linear regression in log-log

% TODO: replace this with octave compatible fitting

% Set up fittype and options.
if inoctave
   error('ordinary least squares not currently supported in octave, use nls')
else
   ft = fittype('poly1');
   fopts = fitoptions( 'Method', 'LinearLeastSquares');
   fopts = setfield(fopts,'Weights', weights);
   [f,~] = fit( logx, logy, ft, fopts );
   ab = fliplr(coeffvalues(f));
end

% transform a to linear space and package a/b
ab = [exp(ab(1)); ab(2)];

% transpose ci to be consistent with stats functions
ci = rot90(confint(f,alpha));
ci(1,:) = exp(ci(1,:));

% generic failure check
ok = all(isreal(ab));


function [ab,ci,ok] = fitLIN(logx,logy,weights,alpha,order,inoctave)
% linear model fit in log-log, equivalent to forcing a line of slope 1 through
% the mean x-y, with option to control the slope using input parameter 'order'

% % not sure if this was ever functional
% % check fitopts
% if isfield(fitopts,'order')
%    if isnumeric(fitopts.order); order = fitopts.order; end
% end

% apply the mask / weights
logx = logx(weights>0);
logy = logy(weights>0);

% impose model order if provided
if ~isnan(order)
   logx = order.*logx;
end

[~,~,ci] = ttest(-logx,-logy,'Alpha',1-alpha);

% note: mean(x-y) = mean(x)-mean(y)
ab = [exp(-(mean(logx)-mean(logy))); order];

% transpose ci to be consistent with stats functions
ci = [exp(ci(1)) exp(ci(2)); ab(2), ab(2)];

% generic failure check
ok = all(isreal(ab));


function [ab,ci,ok] = fitMED(logx,logy,weights,order,inoctave)
% force a line of slope 'order' through the median x-y

% % not sure why this was here, order is passed in with default 1, maybe i was
% gonna do away wiht that or maybe i was testing here before implementing that
% order = 1;
% if isfield(fitopts,'order')
%    order = fitopts.order;
% end

% apply the mask / weights
logx = logx(weights>0);
logy = logy(weights>0);

logx = order*logx;

if inoctave
   pval = nan; % ranksum and kruskalwallis both supported, need to implement
else
   pval = signrank(-logx,-logy); % or ranksum or kruskalwallis
end

% med(x-y)!=med(x)-med(y)
ab = [exp(-(median(logx)-median(logy))); order];

% non-parametric test, no ci
ci = [ab(1), ab(1); ab(2), ab(2)];

% could return to this later
%bootfun = @(x,y)(median(y)-median(x));
%bootci(100,bootfun(logx,logy))

% generic failure check
ok = all(isreal(ab));


function [ab,ci,ok] = fitENV(logx,logy,weights,order,refqtls,inoctave)
% force a line of slope 'order' through any two points 'refpoints' that
% together define an 'envelope'. default x refpoint is median(x). To control
% the vertical location of the line, set y refpoint higher or lower while
% keeping x refpoint constant.

% note: require that quantiles are passed in rather than precomputed refpoints
% so this can use the log values or linear values

% % removed fitopts for now
%    % check fitopts
%       if isfield(fitopts,'order')
%          if isnumeric(fitopts.order); order = fitopts.order; end
%       end
%
%       if isfield(fitopts,'quantile')
%          quantile = fitopts.quantile;
%       end

% apply the mask / weights
logx = logx(weights>0);
logy = logy(weights>0);
logx = order.*logx;

% force the line through the provided quantile
if inoctave
   xbar = quantile(logx,refqtls(1),1,8);
   ybar = quantile(logy,refqtls(2),1,8);
else
   xbar = quantile(logx,refqtls(1),'Method','approximate');
   ybar = quantile(logy,refqtls(2),'Method','approximate');
end

% note: mean(x-y) = mean(x)-mean(y)
ab = [ exp(-(xbar-ybar)); order];

% transpose ci to be consistent with stats functions
ci = [nan nan; nan, nan];

% generic failure check
ok = all(isreal(ab));


function [ab,ci,ok] = fitQTL(logx,logy,weights,alpha,order,qtl,Nboot,inoctave)

% quantile regression
if inoctave
   error('quantile regression not currently supported in octave, use nls')
end

% % If fitopts is abandoned, need to figure out how to deal with extra
% parameters for quantile regression.
% if isfield(fitopts,'qtl')
%    qtl = fitopts.pctl;
%    order = fitopts.order; % 1=linear regression
%    Nboot = fitopts.Nboot;
%    % alpha = fitopts.alpha;
% elseif isnan(qtl)
%    qtl = 0.05;
% end

if isnan(qtl)
   qtl = 0.05;
end

% apply the mask / weights
logx = logx(weights>0);
logy = logy(weights>0);

% fit a,b using quantile regression
[ab,s] = bfra.deps.quantreg(logx,logy,qtl,order,Nboot,1-alpha);

% transform a to linear space and package a/b
ab = [exp(ab(1)); ab(2)];

% transpose ci to be consistent with stats functions
ci = transpose(s.ci_boot);   % comes in the same order as confint
ci(1,:) = exp(ci(1,:));

% generic failure check
ok = all(isreal(ab));


% function [ab,ci,ok] = fitMLE(logx,logy,weights,alpha,sigx,sigy,rxy)
%
% % Set default values for maximum likelihood estimation
% if nargin == 2
%    sigx     =  std(logx);       % error in x
%    sigy     =  std(logy);       % error in y
%    rxy      =  0;               % correlation b/w error in x and y
%    alpha    =  0.68;            % confidence level
% end
%
% % fit
% [ab,s] = yorkfit(logx,logy,sigx,sigy,rxy,1-alpha);
%
% ab = [exp(ab(1)); ab(2)];
%
% % transpose ci to be consistent with stats functions
% ci = [exp(s.a_L), exp(s.a_H); s.b_L, s.b_H];
%
% % generic failure check
% ok = true;
% if any(~isreal(ab))
%    ok = false;
% end


function [ab,ci,ok,fselect] = fitNLS(x,y,logx,logy,weights,alpha,inoctave)

if inoctave
   [ab,ci,ok,fselect] = fitNLS_octave(x,y,logx,logy,weights,alpha);
else
   try
      [ab,ci,ok,fselect] = fitNLS_matlab(x,y,logx,logy,weights,alpha);
   catch
      [ab,ci,ok,fselect] = fitNLS_octave(x,y,logx,logy,weights,alpha);
   end
end

function [Fit,ok] = evalFit(ab,x,y,ci,ok)

% ok is from the fitting function, passed in here but not used
if ok == false
   % error? 
end

Fit.ab = ab;

% all ci's should already be transformed to this form:
Fit.a = ab(1);
Fit.b = ab(2);
Fit.aL = ci(1,1);
Fit.aH = ci(1,2);
Fit.bL = ci(2,1);
Fit.bH = ci(2,2);

Fit.rsq = bfra.deps.rsquare(y,ab(1).*x.^ab(2));
Fit.pvalue = nan;
Fit.N = numel(y);
Fit.x = x;
Fit.y = y;

% generic failure check
ok = all(isreal(ab));

%    % any log-log regressions need the ci's transormed like this:
%    aL      = exp(ci(1,1)); % 95% CI
%    aH      = exp(ci(1,2));
%    bL      = ci(2,1);      % = betaL
%    bH      = ci(2,2);      % = betaH

%    % any nlinfit regressions should already be in teh right order:
%    aL      = ci(1,1); % for confint: ci(1,1);
%    aH      = ci(1,2); % for confint: ci(2,1);
%    bL      = ci(2,1); % for confint: ci(1,2);
%    bH      = ci(2,2); % for confint: ci(2,2);

% this does not work if robust fitting is used
%r2      = 1-sum(R.^2)/sum((y-mean(y)).^2); % for fit: gof.rsquare;
%figure; loglog(x,y,'o'); hold on; loglog(x,ab(1).*x.^ab(2))


function [ab,ci,ok,fselect] = fitNLS_matlab(x,y,logx,logy,weights,alpha)

% initial estimates using log-log linear fit
ok = true;
ab0 = [ones(size(x)) logx]\logy;
ab0 = [exp(ab0(1)), ab0(2)];

% to use user-specified weights:
%opts = statset('Display','off','RobustWgtFun',[]);
%ab = nlinfit(q,dqdt,fnc,ab0,opts,'Weights',weights);

% initialize r2
rsq0 = bfra.deps.rsquare(y,ab0(1).*x.^ab0(2)); 
rsq = rsq0;

% 'nlinfit' function options
fnc = @(ab,x)ab(1).*x.^ab(2);

% fnc = @(ab,x)ab(1).^(3-2.*ab(2)).*x.^ab(2);

% opts1 = statset('Display','off','RobustWgtFun','bisquare');
opts1 = statset('Display','off','RobustWgtFun','bisquare');
opts2 = statset('Display','off');

% 'fit' function options
ftype = fittype(@(a,b,x) (a.*x.^b));

opts3 = fitoptions('Method','NonlinearLeastSquares','Display',...
   'off','Robust','Bisquare','StartPoint',[ab0(1) ab0(2)]);

opts4 = fitoptions('Method','NonlinearLeastSquares',          ...
   'Display','off','StartPoint',[ab0(1) ab0(2)]);

%  Summary of the method:

%  start with linear=rsq0, set rsq=rsq0
%  try nlinfit=rsq1, if rsq1>rsq, set rsq=rsq1 and select nlinfit robust
%  else, try fit=rsq3, if rsq3>rsq, set rsq=rsq3 and select fit robust
%  else, select 'none', rsq still equals rsq0
%  if 'none', try non-robust nlinfit=rsq2, if rsq2>rsq, set rsq=rsq2 and
%  select nlinfit non-robust
%  else

% try robust nonlinear least squares fitting
ab1ok = true;
try
   [ab1,R1,~,C1] = nlinfit(x,y,fnc,ab0,opts1); % R=resids,C=error variance
   rsq1 = bfra.deps.rsquare(y,ab1(1).*x.^ab1(2));

catch ME

   if (strcmp(ME.identifier,'stats:nlinfit:NoUsableObservations'))

      msg = 'Fitting failed using nlinfit at ab1';
      causeException = MException('BFRA:fitab:fitting',msg);
      ME = addCause(ME,causeException);

   end
   ab1ok = false;
   % rethrow(ME)
end

% if nlinfit worked and it's 'better' than rsq (here, rsq0), select it
if ab1ok && rsq1 > rsq && rsq1 > 0

   fselect = 'nlinfit_robust';
   rsq = rsq1;
else

   % try curve fitting functions
   ab3ok = true;
   try
      f3 = fit(x,y,ftype,opts3);
      ab3 = coeffvalues(f3);
      rsq3 = bfra.deps.rsquare(y,ab3(1).*x.^ab3(2));

   catch ME

      if (strcmp(ME.identifier,'curvefit:fit:infComputed'))

         msg = 'Fitting failed using fit at ab3';
         causeException = MException('BFRA:fitab:fitting',msg);
         ME = addCause(ME,causeException);
      end
      ab3ok = false;
      % rethrow(ME)
   end

   % if fit worked, select it
   if ab3ok && rsq3 > rsq && rsq3 > 0

      fselect = 'fit_robust';
      rsq = rsq3;
   else
      fselect = 'none';

   end
end

% if neither nlinfit nor fit worked, try non-robust fitting
if strcmp(fselect,'none')

   ab2ok = true;
   try
      [ab2,R2,~,C2] = nlinfit(x,y,fnc,ab0,opts2);
      rsq2 = bfra.deps.rsquare(y,ab2(1).*x.^ab2(2));

   catch ME

      if (strcmp(ME.identifier,'stats:nlinfit:NoUsableObservations'))

         msg = 'Fitting failed using nlinfit at ab2';
         causeException = MException('BFRA:fitab:fitting',msg);
         ME = addCause(ME,causeException);
      end
      ab2ok = false;
      %rethrow(ME)
   end

   if ab2ok && rsq2 > rsq && rsq2 > 0

      fselect = 'nlinfit';
      rsq = rsq2;

   else                            % try curve fitting functions

      ab4ok = true;
      try
         f4 = fit(x,y,ftype,opts4); ab4 = coeffvalues(f4);
         rsq4 = bfra.deps.rsquare(y,ab4(1).*x.^ab4(2));

      catch ME

         if (strcmp(ME.identifier,'curvefit:fit:infComputed'))

            msg = 'Fitting failed using fit at ab4';
            causeException = MException('BFRA:fitab:fitting',msg);
            ME = addCause(ME,causeException);
         end
         ab4ok = false;
         %rethrow(ME)
      end

      % we don't compare with rsq2 because we already know its <rsq0
      if ab4ok && rsq4 > rsq && rsq4 > 0

         fselect = 'fit';
         rsq = rsq4;
      else
         fselect = 'none';
      end
   end
end

% finally, if rsq is still low but linear rsq is good, choose lin
if strcmp(fselect,'none') && rsq > 0
   fselect = 'linear';
elseif rsq < 0
   % NOTE: nov 2022, i think in some cases we can get here and rsq < 0 so I
   % added this option , previously there was no else, just end
   fselect = 'none';
end

switch fselect

   case 'none'
      ok = false;   % should never occur with option linear
      ab = [nan,nan]; % turns out can occur if q vs dqdt is decreasing
      ci = [nan nan; nan nan];
      
   case 'nlinfit_robust'
      ci = nlparci(ab1,R1,'covariance',C1,'alpha',alpha);
      ab = ab1;

   case 'nlinfit'
      ci = nlparci(ab2,R2,'covariance',C2,'alpha',0.68);
      ab = ab2;

   case 'fit_robust'
      ab = ab3;
      ci = transpose(confint(f3,alpha));

   case 'fit'
      ab = ab4;
      ci = transpose(confint(f4,alpha));

   case 'linear'

      [ab,ci] = regress(logy,[ones(size(y)) logx]);
      ci(1,:) = exp(ci(1,:));
      ab = [exp(ab(1)); ab(2)];

      % might check metrics such as islineconvex(y), and if x<xmin where
      % xmin is some very small flow value below which the data is corrupt
end


function [ab,ci,ok,fselect] = fitNLS_octave(x,y,logx,logy,weights,alpha)

% initial estimates using log-log linear fit
ok = true;
ab0 = [ones(size(x)) logx]\logy;
ab0 = [exp(ab0(1)), ab0(2)];

% initialize r2
rsq0 = bfra.deps.rsquare(y,ab0(1).*x.^ab0(2));
rsq = rsq0;

% 'nlinfit' function options
fnc = @(ab,x)ab(1).*x.^ab(2);

opts2 = statset('Display','off');

%  Summary of the method:

%  start with linear=rsq0, set rsq=rsq0
%  try non-robust nlinfit=rsq2, if rsq2>rsq, set rsq=rsq2 and
%  select nlinfit non-robust
%  else

% try non-robust nonlinear least squares fitting
ab2ok = true;
try
   [ab2,R2,~,C2] = nlinfit(x,y,fnc,ab0,opts2);
   rsq2 = bfra.deps.rsquare(y,ab2(1).*x.^ab2(2));

catch ME

   if (strcmp(ME.identifier,'stats:nlinfit:NoUsableObservations'))

      msg = 'Fitting failed using nlinfit at ab2';
      causeException = MException('BFRA:fitab:fitting',msg);
      ME = addCause(ME,causeException);
   end
   ab2ok = false;
   %rethrow(ME)
end

if ab2ok && rsq2 > rsq && rsq2 > 0

   fselect = 'nlinfit';
   rsq = rsq2;
else
   fselect = 'none';
end

% finally, if rsq is still low but linear rsq is good, choose lin
if strcmp(fselect,'none') && rsq > 0
   fselect = 'linear';
elseif rsq < 0
   fselect = 'none';
end

switch fselect

   case 'none'
      ok = false;
      ab = [nan,nan];
      ci = [nan nan; nan nan];

   case 'nlinfit'
      ci = nlparci_octave(ab2, C2, 0.68);
      ab = ab2;
      
   case 'linear'

      %[B, BINT, R, RINT, STATS] = regress (Y, X, [ALPHA])
      
      [ab,ci] = regress(logy,[ones(size(y)) logx]);
      ci(1,:) = exp(ci(1,:));
      ab = [exp(ab(1)); ab(2)];
end


function ci = nlparci_octave(beta, CovB, alpha)

% INPUTS:
%   beta: coefficients from nlinfit
%   CovB: covariance matrix from nlinfit
%   alpha: desired confidence level (e.g., 0.68 for 68%)
%
% OUTPUTS:
%   ci_lower: lower bounds of the confidence intervals
%   ci_upper: upper bounds of the confidence intervals

n = length(beta); % Number of coefficients
dof = n - 1; % Degrees of freedom
t_score = tinv(1 - (1 - alpha) / 2, dof); % t-score for desired confidence level
se = sqrt(diag(CovB)); % Standard errors of the coefficients
ci_lower = beta' - t_score * se; % Lower bounds of the confidence intervals
ci_upper = beta' + t_score * se; % Upper bounds of the confidence intervals
ci = [ci_lower, ci_upper];


%% INPUT PARSER
function [weights, order, mask, qtl, refqtls, Nboot, alpha, plotfit] = ...
   parseinputs(q, dqdt, method, funcname, varargin)

methodslist = {'nls','ols','mle','qtl','mean','median','envelope'};
validmethod = @(x) any(validatestring(x, methodslist));

persistent parser
if isempty(parser)
   parser = inputParser;
   parser.FunctionName = funcname;
   parser.StructExpand = false;
   parser.addRequired( 'q',                          @isnumeric   );
   parser.addRequired( 'dqdt',                       @isnumeric   );
   parser.addRequired( 'method',                     validmethod  );
   parser.addParameter('weights',  1,                @isnumeric   );
   parser.addParameter('order',    nan,              @isnumeric   );
   parser.addParameter('mask',     1,                @islogical   );
   parser.addParameter('quantile', 0.05,             @isnumeric   );
   parser.addParameter('refqtls',  [0.50 0.50],      @isnumeric   );
   parser.addParameter('Nboot',    100,              @isnumeric   );
   parser.addParameter('alpha',    0.68,             @isnumeric   );
   parser.addParameter('plotfit',  false,            @islogical   );
   parser.addParameter('fitopts',  struct(),         @isstruct    );
end
parse(parser,q,dqdt,method,varargin{:});

weights  = parser.Results.weights;
order    = parser.Results.order;
mask     = parser.Results.mask;
qtl      = parser.Results.quantile;
refqtls  = parser.Results.refqtls;
Nboot    = parser.Results.Nboot;
alpha    = parser.Results.alpha;
plotfit  = parser.Results.plotfit;
fitopts  = parser.Unmatched;

if isscalar(weights) && weights == 1
   weights = ones(size(q));
end

if isscalar(mask) && mask == 1
   mask = true(size(q));
end

% NOTE: fitopts is not implemented, but see bfra.Fit, where it could be used
% to simplify calling this function from wrapper functions. Using the
% unmatched method, it can be used to pass in arbitrary fitopts accepted
% by any function but requires that the user know what to pass in.

% could require:
% if method = 'qtl', fitopts.quantile, fitopts.Nboot
% if method = 'mle', fitopts.sigx, fitopts.sigy, fitopts.rxy
% for all methods, fitopts.order, fitopts.alpha, fitopts.