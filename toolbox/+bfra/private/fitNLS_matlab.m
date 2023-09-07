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

end
