function stats = bootstrapci(x,y,ab0,Fcost,Nboot,alpha,opts)

% calculate confidence intervals using bootstrap resampling of residuals      
   
% see the methods i used in yorkfit to clarify how to define the cost
% fucntion for linear regression, the one in here might not be right, might
% be specific

% i also had a note to revisit this after getting this function to work, to
% compute bootstrap ci's on custom function passed to fitdist
% https://www.research.manchester.ac.uk/portal/files/62039509/q_weibull.pdf

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

   ab0                = fliplr(ab0');
   stats.yhat        = yhat;
   stats.xfit        = sort(x(:,1));
   stats.yfit        = ab0(1)+ab0(2).*stats.xfit;
   stats.resids      = resid;
   stats.ab_boot     = fliplr(mean(abboot));
   stats.se_boot     = fliplr(abse);
   stats.ci_boot     = fliplr(abci);
   stats.yhatci_boot = fliplr(yhatci);
   stats.yfitci_boot = fliplr(yfitci);

% mgc rsq statistic is not relevant to quantile regression, see method here
% https://stats.stackexchange.com/questions/129200/r-squared-in-quantile-regression



% abse is std. dev of bootstrapped coefficients
% this computes the student's CI's from the standard errors
% N       = numel(x);
% alpha   = 0.05;
% t_c     = tinv(1-alpha/2,N-2);
% a_ci    = mean(pboot(:,2))+t_c*pse(2)*[-1 1];
% b_ci    = mean(pboot(:,1))+t_c*pse(1)*[-1 1];

% but instead, use bootstrapped confidence intervals on slope and intercept
% bootstrap options: 'norm','per','cper','bca','student'
% takes way too long
% norm = 0.7515 seconds
% per = 0.7761
% cper = 0.7532
% 'bca' (default) fails on call to jacknife
% 'stud' = 67 sec, also requires more advnaced usage I am unclear on
