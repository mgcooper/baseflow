function [hFits,Picks,Fits] = bfra_plotdqdt(q,dqdt,varargin)
%BFRA_PLOTDQDT Plots the log-log q vs dq/dt with options to select the
%portion of data to fit and then fits the data
% 
%  Syntax:
%     [hFits,Picks,Fits] = bfra_plotdqdt(q,dqdt)
%     [hFits,Picks,Fits] = bfra_plotdqdt(_,'fitmethod',fitmethod)
%     [hFits,Picks,Fits] = bfra_plotdqdt(_,'pickmethod',pickmethod)
%     [hFits,Picks,Fits] = bfra_plotdqdt(_,'weights',weights)
%     [hFits,Picks,Fits] = bfra_plotdqdt(_,'useax',axis_object)
% 
%  Required inputs:
%  q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%  dqdt        =  discharge rate of change (L T^-2)
% 
%  Optional name-value pairs:
% 
% 
%  See also getdqdt, fitdqdt

% NOTE: now that pickFitter calls bfra_fitab, this function does everything
% that an official workflow would do, i think, and therefore should be
% renamed eventually (except it doesn't pick events)

% NOTE: rain is optional b/c at this point, events are picked

%-------------------------------------------------------------------------------  
% input parser
p               = MipInputParser;
p.FunctionName  = 'bfra_plotdqdt';
p.CaseSensitive = false;

validq         = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','column','size',size(dqdt)},            ...
                     'BFRA_plotdQdt','q',1);
validqdt       = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','column','size',size(q)},               ...
                     'BFRA_plotdQdt','dqdt',2);
validfitmethod = @(x)validateattributes(x,{'char','string'},         ...
                     {'scalartext'},                                 ...
                     'BFRA_plotdQdt','fitmethod');
validpickmethod= @(x)validateattributes(x,{'char','string'},         ...
                     {'scalartext'},                                 ...
                     'BFRA_plotdQdt','pickmethod');
validplotopt   = @(x)validateattributes(x,{'logical','scalar'},      ...
                     {'nonempty'},                                   ...
                     'BFRA_plotdQdt','plotfits');
validweights   = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','column','size',size(q)},               ...
                     'BFRA_plotdQdt','weights');
validax        = @(x)validateattributes(x,                           ...
                     {'matlab.graphics.axis.Axes','char'},           ...
                     { 'scalar' },     ...
                     'BFRA_plotdQdt','ax');
validrefpoints = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','vector','numel',2},                    ...
                     'BFRA_plotdQdt','refpoints');
validtimestep  = @(x)validateattributes(x,{'numeric','duration'},    ...
                     {'nonempty'},                                   ...
                     'BFRA_plotdQdt','timestep');
validprecision = @(x)validateattributes(x,{'numeric'},               ...
                     {'nonempty'},                                   ...
                     'BFRA_plotdQdt','precision');                     
validblate     = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','scalar'},                              ...
                     'BFRA_plotdQdt','blate');
validrain      = @(x)validateattributes(x,{'numeric'},               ...
                     {'real','column','size',size(dqdt)},            ...
                     'BFRA_plotdQdt','rain');

p.addRequired(   'q',                           validq            );
p.addRequired(   'dqdt',                        validqdt          );
p.addParameter(  'fitmethod', 'nls',            validfitmethod    );
p.addParameter(  'pickmethod','none',           validpickmethod   );
p.addParameter(  'plotfits',  true,             validplotopt      );
p.addParameter(  'showfig',   true,             @(x)islogical(x)  );
p.addParameter(  'weights',   ones(size(q)),    validweights      );
p.addParameter(  'rain',      zeros(size(q)),   validrain         );
p.addParameter(  'ax',        'none',           validax           );
p.addParameter(  'refpoints', nan,              validrefpoints    );
p.addParameter(  'blate',     1.0,              validblate        );
p.addParameter(  'precision', 1,                validprecision    );
p.addParameter(  'timestep',  1,                validtimestep     );
p.addParameter(  'eventID',   '',               @(x)ischar(x)     );
p.addParameter(  'labelplot', true,             @(x)islogical(x)  );

p.parseMagically('caller');

weights  = p.Results.weights;

% INIT OUTPUT
[hFits,Fits,Picks] = initOutput();

%------------------------------------------------------------------------------
   
   % Prep fits
   [~,~,logx,logy,weights,ok] = bfra_prepfits(q,dqdt,'weights',weights);
   
   if ok == false
      return;
   end
   
   % Pick fits
   Picks = fitSelector(logx,logy,weights,pickmethod,rain);
   
   % Fit picks
   Fits  = pickFitter(Picks,fitmethod);
   
   % plot the fits
   hFits = plotFits(Fits,Picks,fitmethod,refpoints,ax,plotfits,         ...
                     showfig,blate,timestep,precision,labelplot);
   
end

% INITIALIZE OUTPUT
function [hFits,Fits,Picks] = initOutput()
   
   % initialize output
   Fits.h = nan; Fits.abols= nan; Fits.abnls = nan; Fits.abqtl = nan;
   Picks.Q = nan; Picks.T = nan; Picks.dQdt = nan; Picks.R = nan; 
   Picks.nPicks = nan; hFits = nan;
   
end

% SELECT FITS

function Picks  = fitSelector(q,dqdt,weights,pickmethod,rain)
   
   switch pickmethod
      
      case 'none'       % do nothing (use the entire event)
         
         istart   = [];
         istop    = [];
         
      case 'auto'       % auto detect transition between early/late time
         
         % if called w/o output, it will generate a figure
         chgpts   = findchangepts(dqdt,   'MaxNumChanges',  2,          ...
                                          'Statistic',      'linear',   ...
                                          'MinDistance',    2           );
         nPicks   = numel(chgpts);
         
         % get the segment start/ends
         istart   = [ 1;                chgpts(1:nPicks) ];
         istop    = [ chgpts(1:nPicks); numel(q);        ]; 
         
         % exclude segments <4. these are always included in the event fit
         rlengths = istop-istart+1;
         ok       = rlengths>4;
         istart   = istart(ok);
         istop    = istop(ok);

      case 'manual'
      
         % pause helps with buggy ginput
         pickFig     = eventPlotter(q,dqdt); pause(0.5);
         pickedPts   = ginputc();            pause(0.5);
         startPts    = pickedPts(1:2:end);
         endPts      = pickedPts(2:2:end);

         close(pickFig);
         
         % for manual, need to find the indices
         istart      = nan(size(startPts));
         istop       = nan(size(startPts));
         
         for n = 1:numel(startPts)
            difStart    = abs(q-startPts(n));
            difStop     = abs(q-endPts(n));
            istart(n)   = findmin(difStart,1,'first');
            istop(n)    = findmin(difStop,1,'first');
         end
         
   end

   % add the full-event to the start/stop indices
   istart      = [istart; 1];
   istop       = [istop; numel(q)];
   nPicks      = numel(istart);
   
   if pickmethod ~= "none"
      fprintf('%.f picks identified +event = %.f\n',nPicks-1,nPicks)
   end
   
   % cycle through the picks and pull out the data
   Picks.Q           = cell(  nPicks,1 );
   Picks.dQdt        = cell(  nPicks,1 );
   Picks.Weights     = cell(  nPicks,1 );
   Picks.Rain        = cell(  nPicks,1 );
   
   % find the indices of the picked points on the q,dqdt data arrays
   for n = 1:nPicks
      Picks.Q{n}        = q(        istart(n):istop(n)   );
      Picks.dQdt{n}     = dqdt(     istart(n):istop(n)   );
      Picks.Weights{n}  = weights(  istart(n):istop(n)   );
      Picks.Rain{n}     = rain(     istart(n):istop(n)   );
   end
      
   Picks.nPicks        = nPicks;
   Picks.istart        = istart;
   Picks.istop         = istop;
   Picks.runlengths    = istart-istop+1;
end

% FIT PICKS

function Fits = pickFitter(Picks,fitmethod)
   
   for n = 1:Picks.nPicks
      
      logq     = Picks.Q{n};
      logdqdt  = Picks.dQdt{n};
      weights  = Picks.Weights{n};
      q        = exp(logq);
      dqdt     = -exp(logdqdt);
      
      switch fitmethod
         
         case {'ols','qtl','nls','mle'}
            Fit   = bfra_fitab(q,dqdt,'nls');
         case 'comp'
            FitO  = bfra_fitab(q,dqdt,'ols','weights',weights);
            FitQ  = bfra_fitab(q,dqdt,'qtl','weights',weights);
            FitN  = bfra_fitab(q,dqdt,'nls','weights',weights);
            
            Fits.abqtl(n,:)   = FitO.ab;
            Fits.abnls(n,:)   = FitN.ab;
            Fits.abqtl(n,:)   = FitQ.ab;
      end
      
      Fits.ab(n,:)      = Fit.ab;
      Fits.xplot(n,:)   = linspace(0.75*min(q),max(q)*1.25,50);
      Fits.yplot(n,:)   = Fits.ab(n,1).*Fits.xplot(n,:).^Fits.ab(n,2);
      
   end
   Fits.nFits  = Picks.nPicks;
end

% PLOT FITS

function h = plotFits(Fits,Picks,fitmethod,refpoints,ax,plotfits,    ...
                        showfig,blate,timestep,precision,labelplot)
   
   if plotfits == true
      if showfig == true
         
         if strcmp(ax,'none')
            % changed this to make a figure instead
            %ax = gca;
            macfig('size','large');
            ax = gca;
         end % else, useax was passed in
         
      else
         macfig('size','large','visible','off');
         ax = gca;
      end
      h.ax = ax;
   else
      h = []; return;
   end

   
   c  =  [  0        0.447    0.741;
            0.85     0.325    0.098;
            0.929    0.694    0.125;
            0.494    0.184    0.556;
            0.466    0.674    0.188;
            0.301    0.745    0.933;
            0.635    0.078    0.184  ];
   
   
   nFits       = Fits.nFits;
   nPlots      = max(nFits,1); % max(nFits-1,1);
   ltext       = repmat({''},nPlots,1);
   
   % this converts the entire event back to linear space
   x           = exp(Picks.Q{end});
   y           = exp(Picks.dQdt{end});
   rain        =     Picks.Rain{end};
   hold on;
   
   % plot the entire event and get ax lims before setting log scale
   h.scatter   = plot(h.ax,x,y,'o', 'MarkerSize',        8,             ...
                                    'MarkerFaceColor',   c(1,:),        ...
                                    'MarkerEdgeColor',   'none'         );
   
   for n = 1:nPlots
      
      % 'comp' not implemented, this is a template
      if strcmp(fitmethod,'comp') 
         abnls       = Fits.abnls(n,:);
         xplot       = Fits.xplot(n,:);
         yplot       = abnls(1).*xplot.^abnls(2);

         h.plots{n}  = plot(h.ax,xplot,yplot,':','Color',c(n+1,:));
         ltext{n}    = bfra_aQbString(abnls,'printvalues',true);
         
      else
%          if Fits.ab(n,2)<0; continue; end
         xplot       = Fits.xplot(n,:);
         yplot       = Fits.yplot(n,:);
         if nPlots == 1
            % if only one plot, use black dots
            h.plots{n}  = plot(h.ax,xplot,yplot,':','Color','k');
         else
            % otherwise cycle through the colors
            h.plots{n}  = plot(h.ax,xplot,yplot,':','Color',c(n+1,:));
         end
         ltext{n}    = bfra_aQbString(Fits.ab(n,:),'printvalues',true);
      end
   end
   
   % remove empty legend text
   ltext    = ltext(~ismember(ltext,''));

% % I moved this up so the lines plot on top, might have wanted it here for
% the case where we plot multiple events 
%    % plot the entire event and get ax lims before setting log scale
%    h.scatter   = plot(h.ax,x,y,'o', 'MarkerSize',        8,             ...
%                                     'MarkerFaceColor',   c(1,:),        ...
%                                     'MarkerEdgeColor',   'none'         );
   
   axis tight; axis square;
   h.ax.XScale = 'log';
   h.ax.YScale = 'log';
   
   % set AutoUpdate,'off' if adding back the text along the line
   %    h.leg       = legend([h.plots{:}],ltext,'Location','best',      ...
   %                   'Interpreter','latex','AutoUpdate','off');

   xlabel(bfra_strings('Q','units',true));
   ylabel(bfra_strings('dQdt','units',true));

   xlimkeep = get(gca,'XLim');
   ylimkeep = get(gca,'YLim');
   
   if isnan(refpoints)
      refpoints   = quantile(y,[0.05 0.95]);    % use the 5th/95th pctl
   end
   
   [hUpper,abUpper]  = bfra_refline(x,y,        'refline',              ...
                                                'upperenvelope',        ...
                                                'timestep', timestep     );
   [hLower,abLower]  = bfra_refline(x,y,        'refline',              ...
                                                'lowerenvelope',        ...
                                                'precision',precision    );
   [hEarly,abEarly]  = bfra_refline(x,y,        'refslope', 3,          ...
                                                'refpoint', refpoints(2) );
   [hLate,abLate]    = bfra_refline(x,y,        'refslope', blate,      ...
                                                'refpoint', refpoints(1) );

   % add the ref-point a/b values
   h.aEarly    = abEarly(1);
   h.bEarly    = abEarly(2);
   h.aLate     = abLate(1);
   h.bLate     = abLate(2);

   % make the ylimits span the minimum dq/dt to the upper envelope at max Q
   if timestep >= 1
      ylowlim     = min(0.8*abLower(1),min(ylimkeep));
      yupplim     = abUpper(1)*max(xlimkeep)^abUpper(2);

      set(gca,'YLim',[ylowlim yupplim]);
   end

   h        = plotrain(h,rain,x,y);

   % I added this so rain is in the legend
   if isfield(h,'hrain') && isaxis(h.hrain)
      ltext    = [ltext 'rain'];
      h.leg    = legend(   [h.plots{:} h.hrain(1)],ltext,               ...
                              'Location','best','Interpreter','latex',  ...
                              'FontSize',11,'AutoUpdate','off');
   else
      h.leg    = legend(   [h.plots{:} hUpper],ltext,                   ...
                              'Location','best','Interpreter','latex',  ...
                              'FontSize',11,'AutoUpdate','off');
   end
                        
%    ff    = figformat('labelinterpreter','latex','linelinewidth',2,   ...
%                      'suppliedline',h.plots{1},'legendlocation',     ...
%                      'northwest'); 
%    h.ff  = ff;

   grid off;

%    fprintf('%.f picks selected to plot\n',numel(ltext))
   
   if labelplot == true
      addlabels(h)
   end
   
   
%    axpos    = plotboxpos(gca);    % only works with correct axes position
%    xtxt     = exp(mean(log(xlimkeep)));
%    addRotatedText(4*xtxt,axb(aEarly,4*xtxt,bEarly),'b=3',bEarly,axpos);
%    addRotatedText(2*xtxt,axb(aLate,2*xtxt,bLate),'b=1',1.5,axpos);
%    addRotatedText(1*xtxt,axb(aMax,1*xtxt,bMax),'upper envelope',1.5,axpos);

end

function addlabels(h)
   
   ya       = 50;
   xa       = (ya/h.aLate)^(1/h.bLate);
   xa       = [xa xa*3];
   ya       = [ya ya];
   ta       = sprintf('$b=%.2f$ ($\\hat{b}$)',h.bLate);

   arrow([xa(2),ya(2)],[xa(1),ya(1)],'BaseAngle',90,'Length',8,'TipAngle',10)
   text(1.05*xa(2),ya(2),ta,'HorizontalAlignment','left')

   xa       = (ya(1)/h.aEarly)^(1/h.bEarly);
   xa       = [xa xa*3];
   ta       = sprintf('$b=%.0f$',h.bEarly);

   arrow([xa(2),ya(2)],[xa(1),ya(1)],'BaseAngle',90,'Length',8,'TipAngle',10)
   text(1.05*xa(2),ya(2),ta,'HorizontalAlignment','left')

end

function h = plotrain(h,rain,x,y)
   
% add rain. scale the circles such that 1 mm of rain equals the size of
   % the plotted circles 
   if sum(rain)==0
      
      h.hrain = nan;
      
   else
      
      % scatter is producing pixelated symbols so I use plot instead
     %sz    = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
     %scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)
     
     % this mimics the way scatter scales the circles
      sz    = h.scatter.MarkerSize + sqrt(pi.*(rain(rain>0)).^2);
      x     = x(rain>0);
      y     = y(rain>0);
      
      hold on;
      for n = 1:numel(sz)
         h.hrain(n) = plot(x(n),y(n),'o','MarkerSize',sz(n), ...
                     'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
   
end


function addRotatedText(xtxt,ytxt,txt,slope,axpos)

% https://stackoverflow.com/questions/52928360/rotating-text-onto-a-line-on-a-log-scale-in-matplotlib
   
   % to add text, need the slope in figure space
   xlims    = xlim;
   ylims    = ylim;
   xfactor  = axpos(1)/(log(xlims(2))-log(xlims(1)));
   yfactor  = axpos(2)/(log(ylims(2))-log(ylims(1)));   % slope adjustment
   atxt     = slope*atand(yfactor/xfactor);           % adjust angle
   
   text(  xtxt,ytxt,txt,                   ...
         'HorizontalAlignment','center',     ...
         'VerticalAlignment', 'bottom',      ...
         'FontSize',12,                      ...
         'rotation',atxt);
end

% PLOT EVENT
function pickFig = eventPlotter(q,dqdt)
   
   pickFig = figure;
   
   myscatter(q,dqdt);
   
end

% DETECT TRANSITION
function [istart, istop] = detectTransition(q,dqdt,istart,istop)
   
   nPicks   = numel(istart);
   rlengths = istop-istart+1;
   
   if nPicks == 3
     % if rlengths(1)>rlengths(2) && rlengths(3)>rlengths(2)

         q1    = q(istart(1):istop(1));
         q2    = q(istart(2):istop(2));
         q3    = q(istart(3):istop(3));
         dq1   = dqdt(istart(1):istop(1));
         dq2   = dqdt(istart(2):istop(2));
         dq3   = dqdt(istart(3):istop(3));
         ab1   = bfra_wols(log(q1),log(-dq1));
         ab2   = bfra_wols(log(q2),log(-dq2));
         ab3   = bfra_wols(log(q3),log(-dq3));

         % three cases we want to :
         % 1: a flat period between two recessions
         % 2: a flat period followed by another one then a recession
         % 2: a recession followed by two flat periods

         if ab1(2)>1 && ab2(2)<1 && ab3(2)>1
            istart(2)   = [];
            istop(2)    = [];
         end

      %end
   end
end