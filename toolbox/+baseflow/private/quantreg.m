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
      % baseflow_get_Qmin, so i think the fliplr is incorrect
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
% % part, but ztest is evaluating whehter s comes from a normal distribution
% % with mean 0 and standard deviation sigma, so my guss is that s is the
% % distribuiton of slopes, and if the mean value of the slopes is zero, then
% % the trend is not signficanct
% [h, sig] = ztest(s,0,sigma,alpha);
