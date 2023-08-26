function [ab,stats]=quantreg(x,y,tau,order,Nboot,alpha)
   %QUANTREG Quantile Regression
   %
   % USAGE: [p,stats]=quantreg(x,y,tau[,order,nboot]);
   %
   % INPUTS:
   %   x,y:    data that is fitted. (x and y should be columns)
   %           Note: that if x is a matrix with several columns then multiple
   %           linear regression is used and the "order" argument is not used.
   %   tau:    quantile used in regression.
   %   order:  polynomial order. (default=1)
   %           (negative orders are interpreted as zero intercept)
   %   nboot:  number of bootstrap surrogates used in statistical
   %           inference.(default=200)
   %
   % stats is a structure with the following fields:
   %      .pse:    standard error on p. (not independent)
   %      .pboot:  the bootstrapped polynomial coefficients.
   %      .yfitci: 95% confidence interval on "polyval(p,x)" or "x*p"
   %
   % [If no output arguments are specified then the code will attempt to make
   % a default test figure for convenience, which may not be appropriate for
   % your data (especially if x is not sorted).]
   %
   % Note: uses bootstrap on residuals for statistical inference.
   % (see help bootstrp)
   % check also: http://www.econ.uiuc.edu/~roger/research/intro/rq.pdf
   %
   % EXAMPLE:
   % x=(1:1000)';
   % y=randn(size(x)).*(1+x/300)+(x/300).^2;
   % [p,stats]=quantreg(x,y,.9,2);
   % plot(x,y,x,polyval(p,x),x,stats.yfitci,'k:')
   % legend('data','2nd order 90th percentile fit','95% confidence interval', ...
   %       'location','best')
   %
   % For references on the method check e.g. and refs therein:
   % http://www.econ.uiuc.edu/~roger/research/rq/QRJEP.pdf
   %
   %  Copyright (C) 2008, Aslak Grinsted

   % LICENSE
   %
   %   Copyright (C) 2008, Aslak Grinsted
   %
   %   This software may be used, copied, or redistributed as long as it is not
   %   sold and this copyright notice is reproduced on each copy made.  This
   %   routine is provided as is without any express or implied warranties
   %   whatsoever.

   % % mgc changes:
   %     replaced the output p with ab and ordered it as [int,slope]
   %     added prepareCurveData
   %     added alpha
   %     ended up adding too many other things

   % mgc added these
   [x,y] = prepCurveData(x,y);
   if isempty(x) || isempty(y) || all(isnan(x)) || all(isnan(y))
      ab=nan; stats=nan; return
   end

   % mgc, define error messages up front
   msg1='Not enough input arguments.';
   msg2='the percentile (tau) must be between 0 and 1.';
   msg3='length of x and y must be the same.';
   msg4='y must be a column vector.';
   msg5='Can not use multi-column x and at the same time specify an order argument.';

   if nargin<3;               error(msg1);   end
   if nargin<4,               order=[];      end
   if nargin<5,               Nboot=200;     end
   if nargin<6,               alpha=0.05;    end % mgc added conf. level
   if (tau<=0)||(tau>=1);     error(msg2);   end
   if size(x,1)~=size(y,1);   error(msg3);   end
   if numel(y)~=size(y,1);    error(msg4);   end

   if size(x,2)==1
      if isempty(order)
         order=1;
      end
      %Construct Vandermonde matrix.
      if order>0
         x(:,order+1)=1;     % mgc make a column of ones
      else
         order=abs(order);
      end
      x(:,order)=x(:,1); %flipped LR instead of
      for n = order-1:-1:1
         x(:,n)=x(:,order).*x(:,n+1);
      end
   elseif isempty(order)
      order=1; %used for default plotting
   else
      error(msg5);
   end

   %Start with an OLS regression
   ab0   = x\y;                           % mgc changed to ab0
   Frho  = @(r)sum(abs(r.*(tau-(r<0))));  % mgc anonymous function
   % mgc added, default is 200*(number of variables)
   opts  = optimset('MaxFunEvals',1000,'Display','off');
   ab    = fminsearch(@(ab)Frho(y-x*ab),ab0,opts);

   if nargout==0
      [xx,six]=sortrows(x(:,order));
      plot(xx,y(six),'.',x(six,order),x(six,:)*ab,'r.-')
      legend('data',sprintf('quantreg-fit ptile=%.0f%%',tau*100),'location','best')
      clear ab
      return
   end

   if nargout>1

      % calculate confidence intervals using bootstrap on residuals
      stats = bootstrapci(x,y,ab,Frho,Nboot,alpha,opts);

   else % don't perform the bootstrap estimation
      %       ab = fliplr(ab');

      % noticed ab flipped incorrectly when calling two outputs from
      % bfra_get_Qmin, so i think the fliplr is incorrect
      ab = fliplr(ab');
   end

   % turns out if bootstrp is performed i still need this in case i don't
   % use the bootstrap ab_boot
   ab = fliplr(ab');

end



% % this is copied out of ktaub to see how the CI's are computed in case I can
% % adapt it to quantreg
% Zup      = norminv(1-alpha/2,0,1);
% Calpha   = Zup * sigma;
% Nprime   = length(C3);
% M1       = (Nprime - Calpha)/2;
% M2       = (Nprime + Calpha)/2 + 1;
%
% % 2-tail limits
% CIlower  = interp1q((1:Nprime),C3,M1);
% CIupper  = interp1q((1:Nprime),C3,M2);
%
%
% % sigma is the standard error, alpha the significance, getting s is the hard
% % part, but ztest is evaluating whehter s comes from a normal distribution with
% % mean 0 and standard deviation sigma, so my guss is that s is the distribuiton
% % of slopes, and if the mean value of the slopes is zero, then the trend is not
% % signficanct
% [h, sig] = ztest(s,0,sigma,alpha);



% % not sure where this came from, must have been something related to
% quantile regression i found or maybe this was something the og author had
% in here commented out
% function ps=invtranspoly(p,kx)
%
% ps=p;
% order=length(p);
% fact=cumprod(1:order);
% kx=cumprod(repmat(kx,1,order));
% for ii=2:order
%     for jj=1:ii-1
%         N=order-jj+1;
%         k=ii-jj;
%         k=min(k,N-k);
%         ps(ii)=ps(ii)+p(jj)*kk(k)*fact(N)/(fact(k)*fact(N-k));
%     end
% end


% % mgc: this is the stuff that the call to bootstrapci replaced
% %calculate confidence intervals using bootstrap on residuals
% yhat     = x*ab;       % mgc changed yfit to yhat
% resid    = y-yhat;
%
% % mgc added 'options' and removed stats from intermediate calls. pboot
% % is two columns of a and b values for each iteration, a=(:,1), b=(:,2)
% Fboot   = @(bootr)fminsearch(@(ab)Frho(yhat+bootr-x*ab),ab,opts)';
% abboot  = bootstrp(Nboot,Fboot,resid);
% abse    = std(abboot);
%
% % mgc stats.pse is the std. deviation of the bootstrapped coefficients
% % this computes the student's CI's from the standard errors
% % N       = numel(x);
% % alpha   = 0.05;
% % t_c     = tinv(1-alpha/2,N-2);
% % a_ci    = mean(abboot(:,2))+t_c*abse(2)*[-1 1];
% % b_ci    = mean(abboot(:,1))+t_c*abse(1)*[-1 1];
%
% % but instead, use bootstrapped confidence intervals on slope and intercept
% % bootstrap options: 'norm','per','cper','bca','student'
% % takes way too long
% % norm = 0.7515 seconds
% % per = 0.7761
% % cper = 0.7532
% % 'bca' (default) fails on call to jacknife
% % 'stud' = 67 sec, also requires more advnaced usage I am unclear on
% Fci   = {@(bootr)fminsearch(@(ab)Frho(yhat+bootr-x*ab),ab,opts)',resid};
% abci  = bootci(Nboot,Fci,'type','cper','alpha',alpha);
% % mgc added alpha input to bootci, note alpha =0.05 is defualt
%
% % mgc this computes the 95th pctl prediction intervals
% qqhat = zeros(size(x,1),Nboot);
% qqfit = zeros(size(x,1),Nboot); % mgc just added this, if breaks size is wrong
% for n=1:Nboot
%    % mgc since x has a column of ones, this produces a vector of
%    % predictions for each bootstrapped slope/intercept pair
%    qqhat(:,n)=x*abboot(n,:)'; % mgc added 'hat'
%    qqfit(:,n)=sort(x)*abboot(n,:)'; % mgc added sort
% end
%
% conflevs   = 100.*[alpha/2 1-alpha/2]; % mgc added conf. levels
%
% yhatci=prctile(qqhat',conflevs)'; % mgc changed yfitci to yhatci
% yfitci=prctile(qqfit',conflevs)'; % mgc changed yfitci to yhatci
%
% % mgc stats.abboot contains the ensemble of bootstrapped coefficients, but I
% % only want the mean, standard error, and confidence intervals
%
% % mgc i switch the order of p so it is [intercept,slope] and renamed it ab
% ab                = fliplr(ab');
% stats.xdata       = x;
% stats.ydata       = y;
% stats.yhat        = yhat;        % note, yhat = yfit, just not sorted
% stats.xfit        = sort(x(:,1));
% stats.yfit        = ab(1)+ab(2).*stats.xfit;
% stats.resids      = resid;
% stats.ab_boot     = mean(abboot);
% stats.se_boot     = fliplr(abse);
% stats.ci_boot     = fliplr(abci);
% stats.yhatci_boot = fliplr(yhatci);
% stats.yfitci_boot = fliplr(yfitci);
%
% mgc rsq statistic is not relevant to quantile regression, see method here
% https://stats.stackexchange.com/questions/129200/r-squared-in-quantile-regression
%
