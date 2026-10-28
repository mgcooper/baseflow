function [ab,ci,ok,fselect] = fitNLS_matlab(x,y,logx,logy,~,alpha)
   %FITNLS_MATLAB Fit -dQ/dt = aQ^b by nonlinear least squares in MATLAB.
   %
   %  [ab,ci,ok,fselect] = fitNLS_matlab(x,y,logx,logy,weights,alpha)
   %
   %  alpha is a confidence level, as in fitab, so nlparci and regress
   %  take the significance level 1-alpha.
   %
   % See also:

   % Scale the same power law before solving. Large differences between
   % Jacobian columns can stop the solver before it reaches the best fit.
   % Keep the original logs for the unchanged linear fallback.
   logxOriginal = logx;
   logyOriginal = logy;
   xScale = exp(mean(logx));
   yScale = exp(mean(logy));
   x = x/xScale;
   y = y/yScale;
   logx = log(x);
   logy = log(y);

   % initial estimates using log-log linear fit
   ok = true;
   ab0 = [ones(size(x)) logx]\logy;
   ab0 = [exp(ab0(1)), ab0(2)];

   % to use user-specified weights:
   %opts = statset('Display','off','RobustWgtFun',[]);
   %ab = nlinfit(q,dqdt,fnc,ab0,opts,'Weights',weights);

   % initialize r2
   rsq0 = baseflow.deps.rsquare(y,ab0(1).*x.^ab0(2));
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
      rsq1 = baseflow.deps.rsquare(y,ab1(1).*x.^ab1(2));

   catch
      % Continue to the next solver if this solver cannot fit the data.
      ab1ok = false;
   end

   % if nlinfit worked and it's 'better' than rsq (here, rsq0), select it
   if ab1ok && rsq1 > rsq && rsq1 > 0

      fselect = 'nlinfit_robust';
      rsq = rsq1;
   else

      % try curve fitting functions
      try
         [f3,~,output3] = fit(x,y,ftype,opts3);
         % Accept the returned iterate only if the solver converged.
         ab3ok = output3.exitflag > 0;
         ab3 = coeffvalues(f3);
         rsq3 = baseflow.deps.rsquare(y,ab3(1).*x.^ab3(2));

      catch
         ab3ok = false;
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
         rsq2 = baseflow.deps.rsquare(y,ab2(1).*x.^ab2(2));

      catch
         ab2ok = false;
      end

      if ab2ok && rsq2 > rsq && rsq2 > 0

         fselect = 'nlinfit';
         rsq = rsq2;

      else                            % try curve fitting functions

         try
            [f4,~,output4] = fit(x,y,ftype,opts4);
            ab4ok = output4.exitflag > 0;
            ab4 = coeffvalues(f4);
            rsq4 = baseflow.deps.rsquare(y,ab4(1).*x.^ab4(2));

         catch
            ab4ok = false;
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
         [ab,C] = restoreParameters(ab1,C1,xScale,yScale);
         ci = nlparci(ab,yScale*R1,'covariance',C,'alpha',1-alpha);

      case 'nlinfit'
         [ab,C] = restoreParameters(ab2,C2,xScale,yScale);
         ci = nlparci(ab,yScale*R2,'covariance',C,'alpha',1-alpha);

      case 'fit_robust'
         [ab,ci] = restoreCurveFit(f3,xScale,yScale,alpha);

      case 'fit'
         [ab,ci] = restoreCurveFit(f4,xScale,yScale,alpha);

      case 'linear'

         [ab,ci] = regress(logyOriginal,[ones(size(y)) logxOriginal],1-alpha);
         ci(1,:) = exp(ci(1,:));
         ab = [exp(ab(1)); ab(2)];

         % might check metrics such as islineconvex(y), and if x<xmin where
         % xmin is some very small flow value below which the data is corrupt
   end

end

function [ab,C] = restoreParameters(theta,Ctheta,xScale,yScale)
   multiplier = yScale/xScale^theta(2);
   ab = [theta(1)*multiplier, theta(2)];
   % Propagate the full covariance through a = yScale*A/xScale^b.
   D = [multiplier, -ab(1)*log(xScale); 0, 1];
   C = D*Ctheta*D';
end

function [ab,ci] = restoreCurveFit(f,xScale,yScale,alpha)
   theta = coeffvalues(f);
   ab = [theta(1)*yScale/xScale^theta(2), theta(2)];
   ci = transpose(confint(f,alpha));
   % At original Q=1, the fitted mean is the original coefficient a.
   ci(1,:) = yScale*predint(f,1/xScale,alpha,'functional','off');
end
