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
   %     -dq/dt = aQ^b to estimate parameters a and b using the specified
   %     fitting method. Valid methods are ordinary least squares (ols),
   %     non-linear least squares (nls), quantile regression (qtl), mean
   %     difference ('mean'), median difference ('median').
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
   %     quantile scalar double, quantile used if 'method' == 'qtl' (quantile
   %              regression)
   %     Nboot    scalar double, bootstrap sample size for quantile regression
   %     plotfit  logical scalar indicating whether to make a plot or not
   %     fitopts  struct whose fields override the same-named options above
   %              (weights, order, mask, quantile, refqtls, Nboot, alpha,
   %              plotfit); an unknown field is an error
   %
   % Notes
   %     weights are set zero anywhere mask is false
   %
   %     Use method 'envelope' to pass a line through an arbitrary x,y pair
   %     (refpoints), specified in terms of the quantile of the x/y data
   %     distributions. this method is similar to 'mean' or 'median', but allows
   %     different ref points for the x/y values, for example the median of the
   %     x values (0.50 quantile) and some other quantile of the y values. The
   %     default (recommended) behavior is to keep the x-quantile = 0.5 and vary
   %     the y-quantile to move the line up and down as desired to define an
   %     "envelope"
   %
   % Example
   %
   %  Generate test data with known parameters a and b, then fit them:
   %
   %     [t, q, dqdt] = baseflow.generateTestData(1e-2, 1.5, 100);
   %     Fit = baseflow.fitab(q, dqdt, 'nls');
   %     fprintf('a = %.4f, b = %.2f\n', Fit.a, Fit.b)
   %
   %  Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
   %
   % See also: prepfits, fitevents

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   persistent inoctave
   if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
   end

   % PARSE INPUTS
   [weights, order, mask, qtl, refqtls, Nboot, alpha, plotfit] = parseinputs( ...
      q, dqdt, method, mfilename, varargin{:});

   % PREP FITS
   [x, y, logx, logy, weights, ok] = baseflow.prepfits( ...
      q, dqdt, 'weights', weights, 'mask', mask);

   % FAST EXIT
   if ok == false
      Fit = nan; return;
   end

   % If 'order' = 1 and the method is 'ols' or 'nls', switch to 'mean'.
   % The 'mean' method forces a line of slope 1. fitOLS and fitNLS ignore
   % 'order'. Do not switch the other methods. The 'mean', 'median', and
   % 'envelope' methods force a line of slope 'order'. plotrefline relies
   % on 'envelope' with 'order' = 1. 'qtl' passes 'order' to quantreg as
   % the polynomial degree. 'mle' errors as unsupported.
   if order == 1 && any(strcmp(method, {'ols', 'nls'}))
      method = 'mean';
   end

   % SWITCH YARD
   fselect = method;

   switch method
      case 'ols'
         [ab,ci,ok] = fitOLS(logx,logy,weights,alpha);
      case 'qtl'
         [ab,ci,ok] = fitQTL(logx,logy,weights,alpha,order,qtl,Nboot,inoctave);
      case 'mle'
         error('mle fitting not currently supported');
         % [ab,ci,ok] = fitMLE(logx,logy,weights,alpha,sigx,sigy,rxy);
      case 'nls'
         [ab,ci,ok,fselect] = fitNLS(x,y,logx,logy,weights,alpha,inoctave);
      case 'mean'
         [ab,ci,ok] = fitLIN(logx,logy,weights,alpha,order);
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
      Fit.h = baseflow.pointcloudplot(q,dqdt,'reflines',{'userfit'}, ...
         'userab',ab,'mask',mask,'usertext',method);
   end

   % use this when stepping through nlinfit
   debug = false;
   if debug == true
      pos = get(0,'defaultfigureposition');
      figure('Position', [pos(1) pos(2) 2*pos(3) pos(4)])
      subplot(1, 2, 1)
      hold on
      loglog(X, y, '-o');
      % Jul 2024 - yfit undefined so commented it out
      % plot(X, yfit, ':');
      xlabel('log Q');
      ylabel('log -dQ/dt');
      legend('data', 'fit');

      subplot(1, 2, 2)
      hold on
      plot(X, y, '-o');
      % Jul 2024 - yfit undefined so commented it out
      % plot(X, yfit, ':');
      xlabel('Q');
      ylabel('-dQ/dt');
      legend('data', 'fit');
   end
end

% FITTING METHODS
function [ab,ci,ok] = fitOLS(logx,logy,weights,alpha)
   % ordinary least squares linear regression in log-log
   %
   % Solve weighted least squares with plain linear algebra, so the method
   % runs on MATLAB and Octave. The result matches the Curve Fitting Toolbox
   % confint(fit(logx,logy,'poly1'), alpha) with fitoptions Weights.

   % Scale each row by the square root of its weight, so the unweighted
   % solve minimizes sum(weights.*resid.^2). Masked points have zero weight
   % and add nothing to the coefficients or the residuals.
   sw = sqrt(weights);
   X = [sw, sw.*logx];
   [Qx,R] = qr(X,0);
   ab = R \ (Qx'*(sw.*logy));
   resid = sw.*logy - X*ab;

   % Compute coefficient standard errors from inv(X'*X) = inv(R)*inv(R)'.
   % fit counts zero-weight (masked) points in the n-2 residual degrees of
   % freedom, so count them here too to match confint.
   dfe = numel(logy) - 2;
   Rinv = R \ eye(2);
   se = sqrt(diag(Rinv*Rinv') * sum(resid.^2) / dfe);

   % Compute t-based intervals at confidence level alpha, one row per
   % coefficient, in the order [intercept; slope]. This is the rot90(confint)
   % layout, which is consistent with the stats functions.
   tcrit = tinv((1 + alpha) / 2, dfe);
   ci = [ab - tcrit*se, ab + tcrit*se];

   % transform a to linear space and package a/b
   ab = [exp(ab(1)); ab(2)];
   ci(1,:) = exp(ci(1,:));

   % generic failure check
   ok = all(isreal(ab));
end

function [ab,ci,ok] = fitLIN(logx,logy,weights,alpha,order)
   % linear model fit in log-log, equivalent to forcing a line of slope 1
   % through the mean x-y, with option to control the slope using input
   % parameter 'order'

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
end

function [ab,ci,ok] = fitMED(logx,logy,weights,order,inoctave)
   % force a line of slope 'order' through the median x-y

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
end

function [ab,ci,ok] = fitENV(logx,logy,weights,order,refqtls,inoctave)
   % force a line of slope 'order' through any two points 'refpoints' that
   % together define an 'envelope'. default x refpoint is median(x). To control
   % the vertical location of the line, set y refpoint higher or lower while
   % keeping x refpoint constant.

   % note: require that quantiles are passed in rather than precomputed
   % refpoints so this can use the log values or linear values

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
end

function [ab,ci,ok] = fitQTL(logx,logy,weights,alpha,order,qtl,Nboot,inoctave)

   % quantile regression
   if inoctave
      error('quantile regression not currently supported in octave, use nls')
   end

   if isnan(qtl)
      qtl = 0.05;
   end

   % 'order' is the quantreg polynomial degree. The fitab parser default
   % is nan, which crashes the quantreg indexing, so apply the quantreg
   % default of 1 (a straight-line quantile fit).
   if isnan(order)
      order = 1;
   end

   % apply the mask / weights
   logx = logx(weights>0);
   logy = logy(weights>0);

   % fit a,b using quantile regression
   [ab,s] = quantreg(logx,logy,qtl,order,Nboot,1-alpha);

   % transform a to linear space and package a/b
   ab = [exp(ab(1)); ab(2)];

   % transpose ci to be consistent with stats functions
   ci = transpose(s.ci_boot);   % comes in the same order as confint
   ci(1,:) = exp(ci(1,:));

   % generic failure check
   ok = all(isreal(ab));
end

function [ab,ci,ok] = fitMLE(logx,logy,~,alpha,sigx,sigy,rxy) %#ok<DEFNU>

   % Set default values for maximum likelihood estimation
   if nargin == 2
      sigx     =  std(logx);       % error in x
      sigy     =  std(logy);       % error in y
      rxy      =  0;               % correlation b/w error in x and y
      alpha    =  0.68;            % confidence level
   end

   % fit
   [ab,s] = yorkfit(logx,logy,sigx,sigy,rxy,1-alpha);

   ab = [exp(ab(1)); ab(2)];

   % transpose ci to be consistent with stats functions
   ci = [exp(s.a_L), exp(s.a_H); s.b_L, s.b_H];

   % generic failure check
   ok = true;
   if any(~isreal(ab))
      ok = false;
   end
end

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

   Fit.rsq = baseflow.deps.rsquare(y,ab(1).*x.^ab(2));
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
end

%% INPUT PARSER
function [weights, order, mask, qtl, refqtls, Nboot, alpha, plotfit] = ...
      parseinputs(q, dqdt, method, funcname, varargin)

   methodslist = {'nls','ols','mle','qtl','mean','median','envelope'};
   validmethod = @(x) any(validatestring(x, methodslist));

   persistent parser
   if isempty(parser)
      parser = inputParser;
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
   parser.FunctionName = funcname;
   parse(parser,q,dqdt,method,varargin{:});

   weights  = parser.Results.weights;
   order    = parser.Results.order;
   mask     = parser.Results.mask;
   qtl      = parser.Results.quantile;
   refqtls  = parser.Results.refqtls;
   Nboot    = parser.Results.Nboot;
   alpha    = parser.Results.alpha;
   plotfit  = parser.Results.plotfit;
   fitopts  = parser.Results.fitopts;

   % Override each same-named parameter with its fitopts field after a type
   % check. fitevents passes this struct to fitab, so a caller can set the
   % per-fit options once. fitab errors on an unknown field or a wrong type,
   % so it never ignores a fitopts field.
   for f = transpose(fieldnames(fitopts))
      value = fitopts.(f{1});
      switch f{1}
         case 'weights'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.weights must be numeric');
            weights = value;
         case 'order'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.order must be numeric');
            order = value;
         case 'mask'
            assert(islogical(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.mask must be logical');
            mask = value;
         case 'quantile'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.quantile must be numeric');
            qtl = value;
         case 'refqtls'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.refqtls must be numeric');
            refqtls = value;
         case 'Nboot'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.Nboot must be numeric');
            Nboot = value;
         case 'alpha'
            assert(isnumeric(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.alpha must be numeric');
            alpha = value;
         case 'plotfit'
            assert(islogical(value), 'baseflow:fitab:invalidFitopt', ...
               'fitopts.plotfit must be logical');
            plotfit = value;
         otherwise
            error('baseflow:fitab:unknownFitopt', ...
               ['unknown fitopts field %s; allowed: weights, order, ' ...
               'mask, quantile, refqtls, Nboot, alpha, plotfit'], f{1});
      end
   end

   % Expand a scalar weight or mask to every point, because prepfits
   % indexes both point by point. The parser default for mask is the
   % numeric 1, so convert it to logical for prepfits.
   if isscalar(weights)
      weights = weights*ones(size(q));
   end

   if isscalar(mask)
      mask = repmat(logical(mask), size(q));
   end

   % Fields that fitopts could hold later, by method (parked design notes):
   % if method = 'qtl', fitopts.quantile, fitopts.Nboot
   % if method = 'mle', fitopts.sigx, fitopts.sigy, fitopts.rxy
   % for all methods, fitopts.order, fitopts.alpha, fitopts.

end
