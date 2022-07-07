function h = bfra_plplot(x,xmin,alpha,varargin)

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
p               = inputParser;
p.FunctionName  = 'bfra_plplot';
p.CaseSensitive = false;
p.KeepUnmatched = true;

addRequired(   p, 'x',                          @(x)isnumeric(x)     );
addRequired(   p, 'xmin',                       @(x)isnumeric(x)     );
addRequired(   p, 'alpha',                      @(x)isnumeric(x)     );
addParameter(  p, 'alphaci',        nan,        @(x)isnumeric(x)     );
addParameter(  p, 'varsym',         '\tau',     @(x)ischar(x)        );
addParameter(  p, 'suppliedaxis',   gca,        @(x)isaxis(x)        );
addParameter(  p, 'trimline',       false,      @(x)islogical(x)     );
addParameter(  p, 'labelplot',      true,       @(x)islogical(x)     );

parse(p,x,xmin,alpha,varargin{:});
alphaci  = p.Results.alphaci;
varsym   = p.Results.varsym;
ax       = p.Results.suppliedaxis;
trimline = p.Results.trimline;
labelplot = p.Results.labelplot;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
% get the complementary cumulative distribution function
   numData     =  numel(x);
   xccp        =  sort(x);
   ccp         =  (numData:-1:1)'./numData;
   refy        =  ccp(find(xccp>=xmin,1,'first'));
   
   % option to extend the line forward a bit (purely aesthetic)
   if trimline == true
      xccfit   =  sort(x(x>=xmin));
      xccfit   =  [xccfit; xccfit(end)*1.2];
   else
      xccfit   =  sort(x); % this extends the line back toward the origin
      xccfit   =  [xccfit; xccfit(end)*1.2]; % this extends the line forward a bit
   end

   % compute the ccdf
   ccfit       =  (xccfit./xmin).^(1-alpha);
   
   % scale the fitted x>xmin ccdf to pass through the refPoint
   ccfit       =  ccfit.*refy; 
   xccfit      =  xccfit(ccfit<=1);
   ccfit       =  ccfit(ccfit<=1);
   
   % plot it
   h.data      =  loglog(ax,xccp,ccp,'o','LineWidth',0.5,               ...
                     'MarkerSize',10,'MarkerFaceColor','w'); hold on;
   h.fit       =  loglog(ax,xccfit,ccfit,'LineWidth',3);   

   % build a legend, labels, etc.
   ltxt1    = ['$' varsym '$ (data)'];
   if ~isnan(alphaci)
      b     = bfra_conversions(alpha,'alpha','b');
      bL    = bfra_conversions(alphaci(1),'alpha','b');
      bH    = bfra_conversions(alphaci(2),'alpha','b');
      ltxt2 = sprintf('MLE fit ($\\hat{b}=%.2f\\ [$%.2f,%.2f$]\\ 95\\%%$ CI)',b,bL,bH);
   else
      ltxt2 = sprintf('MLE fit ($b=%.2f$)',bfra_conversions(alpha,'alpha','b'));
   end
   xlabel('$x$');
   ylabel(['$p(' varsym '\ge x)$'],'Interpreter','latex'); 
   legend(ltxt1,ltxt2,'interpreter','latex','location','southeast')
   
   figformat('suppliedline',h.fit,'linelinewidth',3);
   
   if labelplot == true
      addlabels(xccfit,ccfit,xmin,xmin-1,xmin+1,b,bL,bH,refy);
   end

   h.ax = gca;
   h.ax.YLim(2)  = 1.5; % add a little white space above P=1

end

function addlabels(xfit,yfit,tau0,tau0L,tau0H,b,bL,bH,yref)
   
   % tau0
   xminc = (tau0H-tau0+tau0-tau0L)/2;
   xa    = [tau0-tau0/2 tau0];
   ya    = yfit(find(xfit>=xa(1),1,'first'));
   ya    = [ya ya];
   ta    = sprintf('$\\hat{\\tau}_0=%.0f\\pm%.0f$ days',tau0,xminc);

   arrow([xa(1),ya(1)],[xa(2),ya(2)],'BaseAngle',90,'Length',8,'TipAngle',10)
   text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right')
   
   % use these to put the text on the right side of the curve
   %    xa    = [xmin+xmin/2 xmin];
   %    text(1.05*xa(1),ya(1),ta)
   
   % tauExp
   xexp  = mean((tau0*(2-bL)/(3-2*bL) + tau0*(2-bH)/(3-2*bH))/2);
   xexpc = mean(abs(xexp-[tau0*(2-bL)/(3-2*bL), tau0*(2-bH)/(3-2*bH)]));
   xa    = [xexp-xexp/2 xexp];
   
   ya    = yfit(find(xfit>=xa(2),1,'first'));
   ya    = [ya ya];
   ta    = sprintf('$\\langle\\tau\\rangle=%.0f\\pm%.0f$ days',xexp,xexpc);

   arrow([xa(1),ya(1)],[xa(2),ya(2)],'BaseAngle',90,'Length',8,'TipAngle',10)
   text(0.95*xa(1),ya(1),ta,'HorizontalAlignment','right')

end