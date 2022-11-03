function [href,ab] = bfra_refline(x,y,varargin)
%BFRA_REFLINE adds a reference line to a point cloud plot
%
% Required inputs:
%  x  = vector of type double (nominally discharge q)
%  y  = vector of type double (nominally discharge rate of change -dq/dt)
%
% Optional inputs:
%  mask     =  vector logical mask to exclude values from fitting
%  refline  =  char indicating what type of refline to plot
%  refslope =  scalar double indicating a user-defined slope
%  userab   =  2x1 double indicating a user-defined intercept,slope pair
%  labels   =  logical indicating whether to add labels
%  refqtls  =  2x1 double, x/y quantiles used if 'method' == 'envelope'
%  plotline =  logical indicating whether to add the line plot (for some cases
%              this function can be used to return the a/b values only)
%  linecolor = rgb triplet indicating the line color
%  precision = scalar double indicating the precision in the x data, used to
%              compute the 'lower envelope'
%  timestep  = scalar double indicating the timestep of the x data, used to
%              compute the 'lower envelope'
%  ax       =  graphic axis to plot into
%
% See also fitab, pointcloudintercept, pointcloud

% NOTE: y comes in as -dq/dt, send it to bfra_fitab as -y, and to refline as y
%-------------------------------------------------------------------------------
p = MipInputParser;
p.FunctionName = 'bfra_refline';
p.PartialMatching = true;
p.addRequired('x',@(x)isnumeric(x));
p.addRequired('y',@(x)isnumeric(x));
p.addParameter('mask',true(size(x)),@(x)islogical(x));
p.addParameter('refline','none',@(x)ischar(x));
p.addParameter('refslope',1,@(x)isnumeric(x));
p.addParameter('userab',[1 1],@(x)isnumeric(x));
p.addParameter('labels',false,@(x)islogical(x));
p.addParameter('refqtls',nan,@(x)isnumeric(x));
p.addParameter('plotline',true,@(x)islogical(x));
p.addParameter('linecolor',[0 0 0],@(x)isnumeric(x));
p.addParameter('precision',1,@(x)isnumeric(x)); % default = 1 m3/s
p.addParameter('timestep',1,@(x)isnumeric(x)); % default = 1 day
p.addParameter('ax',nan,@(x)isaxis(x));

p.parseMagically('caller');

refline     = p.Results.refline;
refslope    = p.Results.refslope;
refqtls     = p.Results.refqtls;
userab      = p.Results.userab;
labels      = p.Results.labels;
precision   = p.Results.precision;
timestep    = p.Results.timestep;
mask        = p.Results.mask;
ax          = p.Results.ax;
%-------------------------------------------------------------------------------
      
% need options for how/if to apply the mask - e.g., we might want to show the
% 'bestfit' to all data, and use the mask for late-time fit. also keep in mind
% bfra_eventphi calls this. mask is default true in parsing. 

   % use this to find the equation of the line
   axb = @(a,x,b) a.*x.^b;
   
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
         F = bfra_fitab(x(mask),-y(mask),'ols','order',1);
         a = F.ab(1);
         b = F.ab(2);
      case 'bestfit'
         F = bfra_fitab(x(mask),-y(mask),'nls');
         a = F.ab(1);
         b = F.ab(2);
      case 'userfit'
         a = userab(1);
         b = userab(2);
      case 'envelope'
         F = bfra_fitab(x(mask),-y(mask),'envelope','refqtls',refqtls,'order',refslope);
         a = F.ab(1);
         b = F.ab(2);
      case 'earlytime'
         if refslope == 1; refslope = 3; end
         F = bfra_fitab(x,-y,'envelope','refqtls',[0.95 0.95],'order',refslope);
         a = F.ab(1);
         b = F.ab(2);
      case 'latetime'
         F = bfra_fitab(x(mask),-y(mask),'envelope','refqtls',[0.5 0.5],'order',refslope);
         a = F.ab(1);
         b = F.ab(2);
      otherwise
         % user must provide a refslope and optionally refpoints or refqtls. if
         % the latter are not provided, use the best linear fit. NOTE: this
         % should probably be removed but keep for now.
         if isnan(refpoints)
            if isnan(refqtls)
               refqtls = [0.5 0.5];
            else
               % deal with refpoints. they aren't really supported anymore
            end
            F = bfra_fitab(x(mask),-y(mask),'envelope','refqtls',refqtls,'order',refslope);
         else
            F = bfra_fitab(x(mask),-y(mask),'mean','order',refslope);
         end
         a = F.ab(1);
         b = F.ab(2);
   end
      
   % send back the ab
   href     = [];       % this gets sent back in case plotline false
   ab       = [a;b];
   
   % Below here only needed if plot is requested
   
   if plotline == true   
      xref     = linspace(xlims(1),xlims(2),100);
      yref     = axb(a,xref,b);
      
      if strcmp(refline,'bestfit')
         href  = loglog(xref,yref,'--','LineWidth',2,'Color',linecolor);
      elseif strcmp(refline,'userfit')
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
   % the precision of the measurements, here I assume that it is 1 m3/s, and
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
