function [href,ab] = bfra_refline(x,y,varargin)
%BFRA_REFLINE

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
p = MipInputParser;
p.FunctionName = 'bfra_refline';
p.PartialMatching = true;
p.addRequired('x',@(x)isnumeric(x));
p.addRequired('y',@(x)isnumeric(x));
p.addParameter('refline','none',@(x)ischar(x));
p.addParameter('refslope',1,@(x)isnumeric(x));
p.addParameter('userab',[1 1],@(x)isnumeric(x));
p.addParameter('labels',false,@(x)islogical(x));
p.addParameter('refpoint',nan,@(x)isnumeric(x));
p.addParameter('plotline',true,@(x)islogical(x));
p.addParameter('linecolor',rgb('black'),@(x)isnumeric(x));
p.addParameter('precision',1,@(x)isnumeric(x)); % default = 1 m3/s
p.addParameter('timestep',1,@(x)isnumeric(x)); % default = 1 day
p.addParameter('ax',nan,@(x)isaxis(x));

p.parseMagically('caller');

refline     = p.Results.refline;   
refpoint    = p.Results.refpoint;
userab      = p.Results.userab;
labels      = p.Results.labels;
precision   = p.Results.precision;
timestep    = p.Results.timestep;
ax          = p.Results.ax;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      

   % use this to find the equation of the line
   axb      = @(a,x,b) a.*x.^b;
   
   % keep track of the original axis limits
   if plotline == true
      if isnan(ax)
         ax    = gca;
      end
      hold on;
      xlims    = get(ax,'XLim');
      ylims    = get(ax,'YLim');
   end
   
   switch refline
      
      case 'upperenvelope'
         b = 1;               % slope = 1
         a = 2/timestep;      % for daily, intercept = 2
      case 'lowerenvelope'
         b = 0;                           % slope = 0 unless stage precision is known
         a = precision*3600*24/timestep;  % 1 m3/s converted to m3/timestep with timestep in days         
      case 'linear'
         F = bfra_fitab(x,-y,'method','ols','order',1);
         a = F.ab(1);
         b = F.ab(2);
      case 'bestfit'
         F = bfra_fitab(x,-y,'method','nls');
         a = F.ab(1);
         b = F.ab(2);
      case 'userfit'
         a = userab(1);
         b = userab(2);
         
      otherwise % user must provide a refslope past here
      
         % use the user provided refslope, then find the intercept
         b = refslope;
         
         if isnan(refpoint)   % use the 5th/95th pctl refpoints

            if refslope==3    % use the upper 95th pctl
               refpoint = quantile(y,0.95);
            elseif refslope<2 % use the lower 5th pctl
               refpoint = quantile(y,0.05);
            end
         end % otherwise use the user-provided refpoint      

         if refslope==3    
            refline  = 'early';
         elseif refslope<2            
            refline  = 'late';
         end

         a  = reflineintercept(x,y,b,refpoint,'power');
   end
      
   % send back the ab
   href     = [];       % this gets sent back in case plotline false
   ab       = [a;b];
   
   % Below here only needed if plot is requested
   
   if plotline == true   
      % plot the line
      xref     = linspace(xlims(1),xlims(2),100);
      yref     = axb(a,xref,b);
      
      if strcmp(refline,'bestfit')
         href  = loglog(xref,yref,':','LineWidth',2,'Color',linecolor);
      else
         href  = loglog(xref,yref,'-','LineWidth',0.5,'Color',linecolor);
      end

      % reset the x,ylims
      set(ax,'XLim',xlims,'YLim',ylims,'TickLabelInterpreter','latex')
      setlogticks(ax);

      if labels == true
         addlabels(a,b,refline)
      end
   
   end

   % if discharge were measured directly, then the lower envelope would be
   % the precision of the measurements, here I assume that's 1 m3/s, and
   % this lower envelope would appear as a horizontal line, also at
   % integer multiples of it. 
   
end

function addlabels(a,b,refline)
   
   % for early and late, we use the early-time form to get the y position
   ylims    = ylim;
   xlims    = xlim;
   
   % use the number of decades to place the labels
   ndecsy   = log10(ylims(2))-log10(ylims(1));
   ndecsx   = log10(xlims(2))-log10(xlims(1));
   
   % place the label 1/2 way b/w the first and second decade
   ya       = 10^(log10(ylims(1))+ndecsy/20);

   switch refline
      
      case {'late','early','userfit','bestfit'}
         xa       = (ya/a)^(1/b);
         
         % make the arrow span 1/10th of the total number of decades
         xa       = [xa 10^(log10(xa)+ndecsx/10)];
         %xa       = [xa xa+10^(ndecs/2)];
         
         ya       = [ya ya];
         
         if b==1 || b==3
            ta    = sprintf('$b=%.0f$',b);
         elseif b==3/2
            ta    = sprintf('$b=%.1f$',b);
         else
            ta    = sprintf('$b=%.2f$',b);
         end
         
         arrow([xa(2),ya(2)],[xa(1),ya(1)],'BaseAngle',90,'Length',8,'TipAngle',10)
         text(1.03*xa(2),ya(2),ta,'HorizontalAlignment','left', ...
               'fontsize',13,'Interpreter','latex')
         
      case 'upperenvelope'

         axpos    = plotboxpos(gca);    % only works with correct axes position
         % xtxt     = exp(mean(log(xlim)));

         xlims    = log10(xlim);
         xtxt     = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
         ytxt     = 2*xtxt;

%          rotatedLogLogText(xtxt,ytxt,'upper envelope',0.22,axpos);

         % I think this works with subplot and 0.22 works with tiledlayout
         rotatedLogLogText(xtxt,ytxt,'upper envelope',3.8,axpos);
         
         % I can't get the rotation right, there's something i don't
         % understand about matlab figure coord's, so the rotation has to
         % be guess and check, some values that tend ot work:
         %rotatedLogLogText(xtxt,ytxt,'upper envelope',0.85,axpos);
         
      case 'lowerenvelope'
         % for now, add this after the fact
% 
%          xlims    = log10(xlim);
%          xtxt     = 10^(xlims(1)+(xlims(2)-xlims(1))/2);
%          ytxt     = 2*xtxt;
         
   end
         
%    % the version with a hat
%    % ta     = sprintf('$b=%.2f$ ($\\hat{b}$)',h.bLate);

end
