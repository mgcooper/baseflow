function [ab,ci,ok,fselect] = fitNLS_octave(x,y,logx,logy,weights,alpha)

   % initial estimates using log-log linear fit
   ok = true;
   ab0 = [ones(size(x)) logx]\logy;
   ab0 = [exp(ab0(1)), ab0(2)];

   % initialize r2
   rsq0 = baseflow.deps.rsquare(y,ab0(1).*x.^ab0(2));
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
      rsq2 = baseflow.deps.rsquare(y,ab2(1).*x.^ab2(2));

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
end