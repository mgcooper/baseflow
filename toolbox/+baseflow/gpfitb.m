function [Fit, bM, alphaM, kM] = gpfitb(x, varargin)
   %GPFITB Fit Generalized Pareto Distribution to recession parameter tau.
   %
   % Syntax
   %
   %     [Fit,b,alpha,k] = gpfitb(x,varargin)
   %
   % Description
   %
   %     [Fit,b,alpha,k] = gpfitb(x) returns Generalized Pareto Distribution fit
   %     to sample x. Fit contains GPD parameter parmhat where
   %     parmhat=gpfit(xhat) and xhat is continuous data believed to follow a
   %     GPD with some known xmin. This function assumes xmin has been
   %     subtracted from the true x such that xhat=x-xmin. If xmin is not
   %     provided, the function assumes xmin=0.
   %
   %     [Fit,b,alpha,k] = gpfitb(x,'xmin',xmin) subtracts user-provided xmin
   %     from data in x. xmin is the threshold parameter.
   %
   % See also: plfitb
   %
   % Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

   % PARSE INPUTS
   [x, xmin, varsymb, bootfit, plotfit, labelplot] = parseinputs(x, varargin{:});

   if nargin == 1
      xmin = 0;
   end
   X = x;
   x = x(x>xmin)-xmin;
   [x,~] = prepCurveData(x,x);

   % get k, klow, and khigh then convert to b
   Dist = fitdist(x,'GeneralizedPareto');
   k_ci = paramci(Dist);

   kM = Dist.k;
   kL = k_ci(1,1);
   kH = k_ci(2,1);

   bL = baseflow.conversions(kL,'k','b');
   bM = baseflow.conversions(kM,'k','b');
   bH = baseflow.conversions(kH,'k','b');

   alphaM = 1+1/kM;
   alphaL = 1+1/kH;
   alphaH = 1+1/kL;

   % need to correct the error term propagation later
   tau0M = Dist.sigma/Dist.k;
   tau0L = k_ci(1,2)/Dist.k;
   tau0H = k_ci(2,2)/Dist.k;

   % bootstrap confidence intervals
   if bootfit == true
      freps = bootstrp(1000,@gpfit,x); % fit
      kreps = freps(:,1); % exponent
      sreps = freps(:,2); % tau0
      breps = baseflow.conversions(kreps,'k','b');
      areps = baseflow.conversions(kreps,'k','alpha');

      % As a rough check on the sampling distribution of the parameter
      % estimators, we can look at histograms of the bootstrap replicates.
      figure; subplot(2,2,1);
      histogram(breps);
      title('Bootstrap estimates of $b$');
      subplot(2,2,2);
      histogram(sreps);
      title('Bootstrap estimates of $\tau_0$');
      subplot(2,2,3);
      histogram(areps);
      title('Bootstrap estimates of $\alpha$');
      subplot(2,2,4);
      histogram(kreps);
      title('Bootstrap estimates of $k$');

   end

   % package output
   Fit.gpdist  = Dist;
   Fit.xmin    = xmin;
   Fit.b       = bM;
   Fit.tau0    = tau0M;
   Fit.tauExp  = tau0M*(2-bM)/(3-2*bM);
   %Fit.tauExp  = gpdist.mean+tau0;
   Fit.k       = kM;
   Fit.alpha   = alphaM;
   Fit.bL      = bL;
   Fit.bH      = bH;
   Fit.kL      = kL;
   Fit.kH      = kH;
   Fit.alphaL  = alphaL;
   Fit.alphaH  = alphaH;
   Fit.tau0L   = tau0L;
   Fit.tau0H   = tau0H;
   Fit.tauExpL = tau0L*(2-bL)/(3-2*bL);
   Fit.tauExpH = tau0H*(2-bH)/(3-2*bH);
   Fit.numtau  = numel(X(X>xmin));

   if bootfit == true
      Fit.breps = breps;
      Fit.tau0reps = sreps;
   end

   if plotfit == true

      % fit a ccdf to the original data and the x-xmin data
      [F,X] = ccdf(X);
      [~,x] = ccdf(x);

      % either use x (ie x-xmin) w/theta=0 or x+xmin w/ theta=xmin
      F2 = gpcdf(x,kM,Dist.sigma,Dist.theta,'upper');

      % add xmin back for the plot, and find the threshold probability
      xplot = x+xmin;
      yref = F(find(X>=xplot(1),1,'first'));

      makesubplot = false;

      % make the figure
      if makesubplot == true

         % plot the ccdf and histogram subplot
         figure('Position',[147   170   831   418]);

         s1 = subtight(1,2,1, ...
            'wstyle','fitted','hstyle','loose','gapstyle','fitted');

      else
         figure;
      end

      % resume plotting
      h.data = loglog(X,F,'o','LineWidth',0.5,'MarkerSize',10,   ...
         'MarkerFaceColor','w'); hold on;
      h.fit = loglog(xplot,F2.*yref,'LineStyle','-','LineWidth',3);

      % h.data = loglog(xplot,F1,'o'); hold on;
      % h.fit = loglog(xplot,F2);

      xlabel('$x$');
      ylabel(['$p(' varsymb '\ge x)$'],'Interpreter','latex');

      ltext1 = ['$' varsymb '$ (data)'];
      ltext2 = sprintf('MLE fit ($\\hat{b}=%.2f\\ [$%.2f,%.2f$]\\ 95\\%%$ CI)',bM,bL,bH);
      h.legend = legend(ltext1,ltext2,'interpreter','latex');
      ax = gca; ax.YLim(2) = 1.5; ax.XLim(2) = xplot(end)*1.2;

      % this works well via guess and check
      h.legend.Position = [0.19 0.38 0.54 0.1];
      % h.legend.Position(1) = 0.9*h.legend.Position(1);
      % h.legend.Position(2) = 0.8*h.legend.Position(2);

      if labelplot == true
         addlabels(Fit,xmin,yref);
      end

      if makesubplot == true

         s2 = subtight(1,2,2, ...
            'wstyle','fitted','hstyle','loose','gapstyle','fitted');
         % [~,~,~,h.histfit] = loghist(X,'dist','GeneralizedPareto','theta',xmin);

         xlabel(['$' varsymb '$']);
         ylabel(['$p(' varsymb ')$'],'Interpreter','latex');

         % commented out for compatibility
         % h.ff = figformat('suppliedline',h.histfit,'linelinewidth',3);

         s2.XLim = s1.XLim;
         h.histlegend = legend(h.ff.backgroundAxis,ltext1,ltext2, ...
            'interpreter','latex','location','southwest');

         childs = h.ff.mainAxis.Children;
         childs(2).FaceAlpha = 0;

         setlogticks(s1);
         setlogticks(s2);
      end


      Fit.thresholdprobability = yref;
      Fit.xplot = xplot;
      Fit.Fplot = F2.*yref;

      % % test using plplot instead
      % aci = [alphaH alphaL];
      % x = X(X>0);
      % [x,~] = prepCurveData(x,x);
      % figure;
      % baseflow.plplotb(x,xmin,alpha,'trimline',true,'alphaci',aci,'labelplot',true);
   end
end

function addlabels(Fit,xmin,yref)

   % tau0
   xminc = (Fit.tau0H-Fit.tau0+Fit.tau0-Fit.tau0L)/2;
   xa = [xmin-xmin/2 xmin];
   ya = Fit.gpdist.cdf(0,'upper')*yref;
   ya = [ya ya];
   ta = sprintf('$\\hat{\\tau}_0=%.0f\\pm%.0f$ days',xmin,xminc);

   baseflow.deps.arrow([xa(1),ya(1)],[xa(2),ya(2)], ...
      'BaseAngle',90,'Length',8,'TipAngle',10)
   text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right')

   % use these to put the text on the right side of the curve
   % xa = [xmin+xmin/2 xmin];
   % text(1.05*xa(1),ya(1),ta)

   % tauExp
   xexp = Fit.tauExp; % just use xmin to keep syntax
   xexpc = (Fit.tauExpH-Fit.tauExp+Fit.tauExp-Fit.tauExpL)/2;
   xa = [xexp-xexp/2 xexp];

   ya = Fit.gpdist.cdf(xexp-xmin,'upper')*yref;
   ya = [ya ya];
   ta = sprintf('$\\langle\\tau\\rangle=%.0f\\pm%.0f$ days',xexp,xexpc);

   baseflow.deps.arrow([xa(1),ya(1)],[xa(2),ya(2)], ...
      'BaseAngle',90,'Length',8,'TipAngle',10)
   text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right')
end

%% INPUT PARSER
function [x, xmin, varsymb, bootfit, plotfit, labelplot] = parseinputs(x, varargin)
   
   parser = inputParser;
   parser.FunctionName = 'baseflow.gpfitb';
   parser.addRequired('x', @isnumeric);
   parser.addParameter('xmin', 0, @isnumeric);
   parser.addParameter('varsym', '\tau', @ischar);
   parser.addParameter('bootfit', false, @islogical);
   parser.addParameter('plotfit', true, @islogical);
   parser.addParameter('labelplot', true, @islogical);
   parser.parse(x, varargin{:});

   xmin     = parser.Results.xmin;
   varsymb  = parser.Results.varsym;
   bootfit  = parser.Results.bootfit;
   plotfit  = parser.Results.plotfit;
   labelplot = parser.Results.labelplot;
end
