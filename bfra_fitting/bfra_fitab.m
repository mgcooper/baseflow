function [Fit,ok] = bfra_fitab(q,dqdt,varargin)
%BFRA_FITAB fits -dq/dt = aQ^b to estimate parameters a and b
% 
% 
%-------------------------------------------------------------------------------
   p = MipInputParser;
   p.addRequired('q',                           @(x)isnumeric(x)     );
   p.addRequired('dqdt',                        @(x)isnumeric(x)     );
   p.addParameter('weights',  ones(size(q)),    @(x)isnumeric(x)     );
   p.addParameter('method',   'nls',            @(x)ischar(x)        );
   p.addParameter('order',    1,                @(x)isnumeric(x)     );
   p.addParameter('mask',     true(size(q)),    @(x)islogical(x)     );
   p.addParameter('quantile', nan,              @(x)isnumeric(x)     );
   p.addParameter('Nboot',    100,              @(x)isnumeric(x)     );
   p.addParameter('plotfit',  false,            @(x)islogical(x)     );
   p.addParameter('fitopts',  struct(),         @(x)isstruct(x)      );
   p.parseMagically('caller');
   
   weights  = p.Results.weights;
   order    = p.Results.order;
   quantile = p.Results.quantile;
   plotfit  = p.Results.plotfit;
   
%-------------------------------------------------------------------------------
   
   [x,y,logx,logy,weights,ok] = bfra_prepfits(q,dqdt, 'weights',weights,...
                                                      'mask',mask);

   % weights will equal zero anywhere mask is false
   
   if ok == false;
      Fit = nan; return;
   end
   
   alpha    = 0.68;
   
   switch method
         
      case 'ols'
         [ab,ci,ok]  = fitOLS(logx,logy,weights,alpha);
      case 'qtl'
         [ab,ci,ok]  = fitQTL(logx,logy,weights,alpha,order,quantile,Nboot,fitopts);
      case 'mle'
         [ab,ci,ok]  = fitMLE(logx,logy,weights,alpha,sigx,sigy,rxy);
      case 'nls'
         [ab,ci,ok,s]= fitNLS(x,y,logx,logy,weights,alpha,fitopts);
      case 'mean'
         [ab,ci,ok]  = fitLIN(logx,logy,weights,alpha,order,fitopts);
      case 'median'
         [ab,ci,ok]  = fitMED(logx,logy,weights,order,fitopts);
      case 'envelope'
         [ab,ci,ok]  = fitENV(logx,logy,weights,order,quantile,fitopts);
   end
      
   
   % NOW THAT FITTING IS DONE, SELECT THE FINAL FIT
   [Fit,ok]   =  evalFit(ab,x,y,ci,ok);
   
   if exist('fs','var')
      Fit.fselect = s;
   end
   
   if plotfit == true
      Fit.h = bfra_pointcloud(q,dqdt,'reflines',{'userfit'},            ...
                              'userab',ab,'mask',mask);
   end
end


% FITTING METHODS
function [ab,ci,ok] = fitOLS(logx,logy,weights,alpha)

   % Set up fittype and options.
            ft       =  fittype(     'poly1'                         );
            fopts    =  fitoptions(  'Method', 'LinearLeastSquares'  );
    fopts.Weights    =  weights;
         [f, ~]      =  fit( logx, logy, ft, fopts ); 
            ab       =  fliplr(coeffvalues(f));

            ab       =  [exp(ab(1)); ab(2)];
            
      % transpose ci to be consistent with stats functions
            ci       =  rot90(confint(f,alpha));
            ci(1,:)  =  exp(ci(1,:));
            
      % generic failure check
         ok = true;
         if any(~isreal(ab))
            ok = false;
         end
   
end

function [ab,ci,ok] = fitMLE(logx,logy,weights,alpha,sigx,sigy,rxy)

   % Set default values for maximum likelihood estimation
      if nargin == 2
            sigx     =  std(logx);       % error in x
            sigy     =  std(logy);       % error in y
            rxy      =  0;               % correlation b/w error in x and y
            alpha    =  0.68;            % confidence level
      end

   % fit 
         [ab,s]      =  yorkfit(logx,logy,sigx,sigy,rxy,1-alpha);

            ab       = [exp(ab(1)); ab(2)];
            
   % transpose ci to be consistent with stats functions
            ci       = [exp(s.a_L), exp(s.a_H); s.b_L, s.b_H];

   % generic failure check
            ok = true;
         if any(~isreal(ab))
            ok = false;
         end
end

function [ab,ci,ok] = fitQTL(logx,logy,weights,alpha,order,quantile,Nboot,fitopts)
                      
   % quantile regression
      if isfield(fitopts,'quantile')
            quantile =  fitopts.pctl;
            order    =  fitopts.order; % 1=linear regression
            Nboot    =  fitopts.Nboot;
          % alpha    =  fitopts.alpha; 
      elseif isnan(quantile)
         quantile    = 0.05;
      end
   
      % apply the mask / weights
      logx     = logx(weights>0);
      logy     = logy(weights>0);
      
      [ab,s]   =  quantreg(logx,logy,quantile,order,Nboot,1-alpha);
      ab       =  [exp(ab(1)); ab(2)];

   % transpose ci to be consistent with stats functions      
      ci       =  transpose(s.ci_boot);   % comes in the same order as confint
      ci(1,:)  =  exp(ci(1,:));
        
   % generic failure check
            ok =  true;
         if any(~isreal(ab))
            ok =  false;
         end
            
end

function [ab,ci,ok] = fitLIN(logx,logy,weights,alpha,order,fitopts)

   % check fitopts
      if isfield(fitopts,'order')
         if isnumeric(fitopts.order); order = fitopts.order; end
      end
      
   % apply the mask / weights
         logx        =  logx(weights>0);
         logy        =  logy(weights>0);
      
         logx        =  order.*logx;
         [~,~,ci]    =  ttest(-logx,-logy,'Alpha',1-alpha);

   % note: mean(x-y) = mean(x)-mean(y)
         ab          =  [exp(-(mean(logx)-mean(logy))); order];
         
   % transpose ci to be consistent with stats functions
         ci          =  [exp(ci(1)) exp(ci(2)); ab(2), ab(2)];
         
   % generic failure check
            ok    =  true;
         if any(~isreal(ab))
            ok    =  false;
         end
     
end

function [ab,ci,ok] = fitMED(logx,logy,weights,order,fitopts)
   
% % not sure why this was here, order is passed in with default 1, maybe i was
% gonna do away wiht that or maybe i was testing here before implementing that
%    order = 1;
%       
%       if isfield(fitopts,'order')
%             order =  fitopts.order;
%       end
      
      % apply the mask / weights
         logx     =  logx(weights>0);
         logy     =  logy(weights>0);
      
         logx     =  order*logx;
         pv       =  signrank(-logx,-logy); % or ranksum or kruskalwallis
   
   % med(x-y)!=med(x)-med(y)
         ab       =  [exp(-(median(logx)-median(logy))); order]; 
   
   % non-parametric test, no ci
         ci       =  [ab(1), ab(1); ab(2), ab(2)];

      % could return to this later
        %bootfun  = @(x,y)(median(y)-median(x));
        %bootci(100,bootfun(logx,logy))
        
     % generic failure check
            ok    =  true;
         if any(~isreal(ab))
            ok    =  false;
         end

end

function [ab,ci,ok] = fitENV(logx,logy,weights,order,quantile,fitopts)
         
   % check fitopts
      if isfield(fitopts,'order')
         if isnumeric(fitopts.order); order = fitopts.order; end
      end
      
      if isfield(fitopts,'quantile')
         quantile = fitopts.quantile;
      end
      
    % force the line through the provided quantile
      if isnan(quantile)
         quantile    = 0.05;
      end
      
   % apply the mask / weights
         logx        =  logx(weights>0);
         logy        =  logy(weights>0);
      
         logx        =  order.*logx;

   % note: mean(x-y) = mean(x)-mean(y)
         xref        =  prctile(logx,100*quantile);
         yref        =  prctile(logy,100*quantile);
         ab          =  [ exp(-(xref-yref)); order];
         
   % transpose ci to be consistent with stats functions
         ci          =  [nan nan; nan, nan];
         
   % generic failure check
            ok    =  true;
         if any(~isreal(ab))
            ok    =  false;
         end
     
end


function [ab,ci,ok,fselect] = fitNLS(x,y,logx,logy,weights,alpha,fitopts)

% initial estimates using log-log linear fit
   ok          =  true;           
   ab0         =  [ones(size(x)) logx]\logy;
   ab0         =  [exp(ab0(1)), ab0(2)];

% iniital rsq
   rsq0        =  rsquare(y,ab0(1).*x.^ab0(2)); rsq = rsq0;
   
   
   % to use user-specified weights:
   %opts    = statset('Display','off','RobustWgtFun',[]);
   %ab      = nlinfit(q,dqdt,fnc,ab0,opts,'Weights',weights);
      
   
   % 'nlinfit' function options
   fnc      =  @(ab,x)ab(1).*x.^ab(2);
   
%    fnc      =  @(ab,x)ab(1).^(3-2.*ab(2)).*x.^ab(2);
   
   opts1    =  statset('Display','off','RobustWgtFun','bisquare');
   opts2    =  statset('Display','off');
   
   % 'fit' function options
   ftype    =  fittype(@(a,b,x) (a.*x.^b));
   
   opts3    =  fitoptions('Method','NonlinearLeastSquares','Display',...
               'off','Robust','Bisquare','StartPoint',[ab0(1) ab0(2)]);
            
   opts4    =  fitoptions('Method','NonlinearLeastSquares',          ...
               'Display','off','StartPoint',[ab0(1) ab0(2)]);

%  Summary of the method:

%  start with linear=rsq0, set rsq=rsq0
%  try nlinfit=rsq1, if rsq1>rsq, set rsq=rsq1 and select nlinfit robust
%  else, try fit=rsq3, if rsq3>rsq, set rsq=rsq3 and select fit robust
%  else, select 'none', rsq still equals rsq0
%  if 'none', try non-robust nlinfit=rsq2, if rsq2>rsq, set rsq=rsq2 and
%  select nlinfit non-robust
%  else

% warning off
% try robust nonlinear least squares fitting
   try
      [ab1,R1,~,C1]   = nlinfit(x,y,fnc,ab0,opts1); % R=resids,C=error variance
      rsq1            = rsquare(y,ab1(1).*x.^ab1(2));
   
   catch ME
   
      if (strcmp(ME.identifier,'stats:nlinfit:NoUsableObservations'))
         
         msg            =  'Fitting failed using nlinfit at ab1';
         causeException =  MException('MATLAB:bfra_fitK:fitting',msg);
         ME             = addCause(ME,causeException);
         
      end
   % rethrow(ME)
   end



% if nlinfit worked and it's 'better' than rsq (here, rsq0), select it
   if exist('ab1','var') && rsq1 > rsq && rsq1 > 0

      fselect  =  'nlinfit_robust';
      rsq      =  rsq1;

   else
      
      % try curve fitting functions
      
      try
         
         f3      =   fit(x,y,ftype,opts3); ab3 = coeffvalues(f3);
         rsq3    =   rsquare(y,ab3(1).*x.^ab3(2));

      catch ME
         
         if (strcmp(ME.identifier,'curvefit:fit:infComputed'))
            
            msg            =  'Fitting failed using fit at ab3';
            causeException =  MException('MATLAB:bfra_fitK:fitting',msg);
            ME             =  addCause(ME,causeException);
            
         end
         %             rethrow(ME)
      end



      % if fit worked, select it
      if exist('ab3','var') && rsq3 > rsq && rsq3 > 0
         
         fselect  =  'fit_robust';
         rsq      =  rsq3;
         
      else
         fselect  =  'none';
         
      end
   end



   % if neither nlinfit nor fit worked, try non-robust fitting
   if strcmp(fselect,'none')

      try
            [ab2,R2,~,C2]   = nlinfit(x,y,fnc,ab0,opts2);
            rsq2            = rsquare(y,ab2(1).*x.^ab2(2));
            
      catch ME
         
         if (strcmp(ME.identifier,'stats:nlinfit:NoUsableObservations'))
            
            msg            =  'Fitting failed using nlinfit at ab2';
            causeException =  MException('MATLAB:bfra_fitK:fitting',msg);
            ME             =  addCause(ME,causeException);
            
         end
         %             rethrow(ME)
      end



      if exist('ab2','var') && rsq2 > rsq && rsq2 > 0
         
            fselect  =  'nlinfit';
            rsq      =  rsq2;
         
      else                            % try curve fitting functions
         
         try
               f4    =  fit(x,y,ftype,opts4); ab4 = coeffvalues(f4);
               rsq4  =  rsquare(y,ab4(1).*x.^ab4(2));
               
         catch ME
            
            if (strcmp(ME.identifier,'curvefit:fit:infComputed'))
               
               msg            =  'Fitting failed using fit at ab4';
               causeException =  MException('MATLAB:bfra_fitK:fitting',msg);
               ME             =  addCause(ME,causeException);
               
            end
            %                 rethrow(ME)
         end



         % we don't compare with rsq2 because we already know its <rsq0
         if exist('ab4','var') && rsq4 > rsq && rsq4 > 0
            
               fselect  =  'fit';
               rsq      =  rsq4;
         else
               fselect  =  'none';
         end
      end


   end

   % finally, if rsq is still low but linear rsq is good, choose lin
      if strcmp(fselect,'none') && rsq > 0
         
            fselect  =  'linear';
      end
   
   

   switch fselect

      case 'none'
         ok       =  false;   % should never occur with option linear
         ab       =  [nan,nan]; % turns out can occur if q vs dqdt is decreasing

      case 'nlinfit_robust'
         ci       =  nlparci(ab1,R1,'covariance',C1,'alpha',alpha);
         ab       =  ab1;
         
      case 'nlinfit'
         ci       =  nlparci(ab2,R2,'covariance',C2,'alpha',0.68);
         ab       =  ab2;
         
      case 'fit_robust'
         ab       =  ab3;
         ci       =  transpose(confint(f3,alpha));

      case 'fit'
         ab       =  ab4;
         ci       =  transpose(confint(f4,alpha));
         
      case 'linear'
         
         [ab,ci]  =  regress(logy,[ones(size(y)) logx]);
         ab       =  [exp(ab(1)); ab(2)];
         ci(1,:)  =  exp(ci(1,:));
         
         % might check metrics such as islineconvex(y), and if x<xmin where
         % xmin is some very small flow value below which the data is corrupt
         
   end
   
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the original method was here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [Fit,ok] = evalFit(ab,x,y,ci,ok)


   Fit.ab      =  ab;

   % all ci's should already be transformed to this form:
   Fit.a       =  ab(1);
   Fit.b       =  ab(2);
   Fit.aL      =  ci(1,1);
   Fit.aH      =  ci(1,2);
   Fit.bL      =  ci(2,1);
   Fit.bH      =  ci(2,2);
   
   Fit.rsq     =  rsquare(y,ab(1).*x.^ab(2));
   Fit.pvalue  =  nan;
   Fit.N       =  numel(y);
   Fit.x       =  x;
   Fit.y       =  y;
   
   % generic failure check
         ok    =  true;
      if any(~isreal(ab))
         ok    =  false;
      end
   
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

