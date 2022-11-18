function stats = bootstrapci(x,y,ab0,Fcost,Nboot,alpha,opts)

% calculate confidence intervals using bootstrap resampling of residuals      

% NOTE: i moved the bootstrap ci stuff out of quantreg to this dedicated
% funciton, but the fitting function in quantreg involves tau, the quantile
% chosen, so it isn't general, so either i have to require this function
% to accept the cost function. Going forward, would be good to have a
% default option that is general linear regression. 

 % Fcost = @(r)sum(abs(r.*(tau-(r<0)))); % should be cost function
   
% need to add a check if x has a column of ones and add one if not   

  %if nargin<4, Fcost = @(r)sum(abs(r.*(tau-(r<0)))); end
   if nargin<6, alpha=0.05;    end % conf. level

   if nargin<7
   % define options and fitting functions
      opts  = optimset('MaxFunEvals',1000,'Display','off');
   end
   
% this would start by getting the slope, rather than passing it in
 % ab0   = x\y;   % initial ols ab to get the initial quantreg ab
 % ab0   = fminsearch(@(ab)Fcost(y-x*ab),ab0,opts);
 
% how this works:
%  - bootstrp draws Nboot samples from resid, applying Fboot to each one
%  - Fboot finds the ab that minimizes the 

% compute the fitted y-values and residuals 
   yhat  = x*ab0;
   resid = y-yhat;
   xsort = sort(x);  % some places need sorted, others don't, pay attention
   
% bootstrap function. bootr are the bootstrapped residuals.
   Fboot = @(bootr)fminsearch(@(ab)Fcost(yhat-x*ab+bootr),ab0,opts)';

% ensemble of ab values (column vectors, a=(:,1), b=(:,2))
   abboot = bootstrp(Nboot,Fboot,resid);
   abse   = std(abboot);

% bootstrapped confidence intervals on ab. the transpose makes x*ab work.
   Fci   =  {@(bootr)fminsearch(@(ab)Fcost(yhat+bootr-x*ab),ab0,opts)',resid};
   abci  =  bootci(Nboot,Fci,'type','cper','alpha',alpha); % default alpha =0.05

% compute the 95th pctl prediction intervals
   yyhat =  zeros(size(x,1),Nboot);
   yyfit =  zeros(size(x,1),Nboot);

% if x has a column of ones, this produces a vector of predictions for
   % each bootstrapped slope/intercept pair    
   for n = 1:Nboot
      yyhat(:,n) = x*abboot(n,:)';    
      yyfit(:,n) = xsort*abboot(n,:)';
   end

   conflevs = 100.*[alpha/2 1-alpha/2];
   yhatci   = prctile(yyhat',conflevs)';
   yfitci   = prctile(yyfit',conflevs)';

   % test for slope significance
   b_samp = abboot(:,1);      % slope is the first column (flipped in output)
   % null hyp is that the mean is zero. h=1 if reject null = mean is not zero =
   % slope is significant
   [h, p] = ztest(b_samp,0,std(b_samp));
   % figure; histogram(b_samp);
   
   ab0               = fliplr(ab0');
   stats.yhat        = yhat;
   stats.xfit        = sort(x(:,1));
   stats.yfit        = ab0(1)+ab0(2).*stats.xfit;
   stats.resids      = resid;
   stats.ab_boot     = fliplr(mean(abboot));
   stats.se_boot     = fliplr(abse);
   stats.ci_boot     = fliplr(abci);
   stats.yhatci_boot = fliplr(yhatci);
   stats.yfitci_boot = fliplr(yfitci);
   stats.significant = h==1;
   

% mgc rsq statistic is not relevant to quantile regression, see method here
% https://stats.stackexchange.com/questions/129200/r-squared-in-quantile-regression

