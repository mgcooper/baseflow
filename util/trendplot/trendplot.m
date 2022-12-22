function h = trendplot(t,y,varargin)
   
%-------------------------------------------------------------------------------
   p                 = magicParser;
   p.FunctionName    = 'trendplot';
   p.PartialMatching = true;
   
   dpos  = [321 241 512 384]; % default figure size

% to get this to work i think i need to first parse if the first input is
% an axis and then pass remaining args to input parser, might also need to
% have mutually exclusive options in json, at minimum to get function hints
% to work as they do with plot()
% p.addOptional('target',       gca,  @(x)isaxis(x)                    );
% % add this back to json to try
% {"name":"target",       "kind":"ordered", 
% "type":[["matlab.graphics.axis.AbstractAxes"], ["matlab.ui.control.UIAxes"]]},

   p.addRequired('t',                  @(x)isnumeric(x) || isdatetime(x));
   p.addRequired('y',                  @(x)isnumeric(x)                 );
   p.addParameter('units',       '',   @(x)ischar(x)                    );
   p.addParameter('ylabeltext',  '',   @(x)ischar(x)                    );
   p.addParameter('xlabeltext',  '',   @(x)ischar(x)                    );
   p.addParameter('titletext',   '',   @(x)ischar(x)                    );
   p.addParameter('legendtext',  '',   @(x)ischar(x)                    );
   p.addParameter('method',      'ols',@(x)ischar(x)                    );
   p.addParameter('alpha',       0.05, @(x)isnumeric(x)                 );
   p.addParameter('anomalies',   true, @(x)islogical(x)                 );
   p.addParameter('quantile',    nan,  @(x)isnumeric(x)                 );
   p.addParameter('figpos',      dpos, @(x)isnumeric(x)                 );
   p.addParameter('useax',       nan,  @(x)isaxis(x)                    );
   p.addParameter('showfig',     true, @(x)islogical(x)                 );
   p.addParameter('errorbars',   false,@(x)islogical(x)                 );
   p.addParameter('errorbounds', false,@(x)islogical(x)                 );
   p.addParameter('reference',   nan,  @(x)isnumeric(x)                 );
   p.addParameter('yerr',        nan,  @(x)isnumeric(x)                 );
   p.addParameter('precision',   nan,  @(x)isnumeric(x)                 );
   p.parseMagically('caller');
   
   useax       = p.Results.useax;
   units       = p.Results.units;
   qtl         = p.Results.quantile; clear quantile
   alpha       = p.Results.alpha;
   precision   = p.Results.precision;
   yerr        = p.Results.yerr;
   varargs     = unmatched2varargin(p.Unmatched);
%-------------------------------------------------------------------------------

   % convert to anomalies etc.
   [t,y,yerr] = prepInput(t,y,yerr,anomalies,reference);
   
   % compute trends
   [ab,err,yfit,yci] = computeTrends(t,y,method,alpha,qtl);   
   
   % update the figure or make a new one
   [h,makeleg,legidx] = updateFigure(useax,showfig,figpos,errorbounds);
   
   % draw the plot
   h     = plotTrend(h,t,y,yfit,yerr,yci,errorbars,errorbounds,varargs);

   % draw the legend
   h     = drawLegend(h,ab,legendtext,units,alpha,err,makeleg,legidx,precision);
 
   %axis tight
   
   ylabel(ylabeltext); xlabel(xlabeltext); title(titletext);
   
   h.ax = gca;
   h.ab = ab;
   h.err = err;
   h.yfit = yfit;
   h.yci = yci;
end

function [t,y,yerr] = prepInput(t,y,yerr,anomalies,reference)
   
   % create a regular time in years, works for both months and years
   if isdatetime(t)
      y0 = year(t(1));           % the first year (double)
      t0 = datetime(y0,1,1);     % start of the first year (datetime)
      t  = years( t-t(1)) + ( y0 + years( t(1) - t0 ) );
   end
   % see old method that checked for months at end

   % convert to anomalies if requested
   if anomalies == true
      if notnan(reference)
         y  = y-mean(reference,1,'omitnan');
      else
         y  = y-mean(y,1,'omitnan');
      end
   end
   
   % if yerr is a scalar, make it a vector of size equal to y
   if isscalar(yerr)
      yerr  = yerr.*ones(size(y));
   end
   
end

%  COMPUTE TRENDS

function [ab,err,yfit,yci] = computeTrends(t,y,method,alpha,qtl)
   
   inan  = isnan(y);
   ncol  = size(y,2);
   ab    = nan(ncol,2);
   err   = nan(ncol,1);
   ci    = nan;
   yci   = nan(size(y,1),2); % confidence bounds for trendline

   % note, conf int's not symmetric for quantile regression, so I use the
   % mean of the lower and upper for now 
   
   % compute trends
   for n = 1:ncol
      if isnan(qtl)
         switch method
            case 'ts'
               % need to eventually merge tsregr and ktaub, the latter
               % doesn't return the intercept and the former doesn't return
               % conf levels or much other detail.
               
               % only get conf levels if requested
               if isnan(alpha)
                  ab(n,:)  = tsregr(t,y(:,n));
               else
                  ab(n,:)  = tsregr(t,y(:,n));
                  out      = ktaub([t,y(:,n)], alpha, false);
                  ci       = [out.CIlower, out.CIupper];
                  err(n)   = mean([ab(n,2)-ci(1),ci(2)-ab(n,2)]);
               end
               
               % not sure we want the setnan
               yfit  = ab(:,1) + ab(:,2)*t'; yfit = yfit';
               yfit  = setnan(yfit,inan);
               
            case 'ols'
               
               if isnan(alpha)
                  ab(n,:)  = olsfit(t,y(:,n));
               else
                  
                  mdl      = fitlm(t,y(:,n));
                  B        = mdl.Coefficients.Estimate;  % Coefficients
                  ci       = coefCI(mdl,alpha);          % coefficent CIs
                  ab(n,:)  = B;
                  err(n)   = ci(2,2)-ab(n,2);            % symmetric for ols
                  [yfit,yci] = predict(mdl,t,'alpha',alpha); % fitted line and CIs
                  
                  % [B,CI] = regress(y(:,n),[ones(size(t)) t],alpha);
                  % CB(:,1)= CI(1,1)+CI(2,1)*t;
                  % CB(:,2)= CI(1,2)+CI(2,2)*t;
                  % CB     = anomaly(CB);          % convert to anomalies?

               end
         end
      else
         % only get conf levels if requested
         if isnan(alpha)
            ab(n,:)     = quantreg(t,y(:,n),qtl);
         else
            [ab(n,:),S] = quantreg(t,y(:,n),qtl,1,1000,alpha);
            ci          = S.ci_boot';
            err(n)      = mean([ab(n,2)-ci(2,1),ci(2,2)-ab(n,2)]);
         end
         
         yfit = ab(:,1) + ab(:,2)*t'; yfit = yfit';
         yfit = setnan(yfit,inan);
         
      end
   end
   
% this plots a histogram of the bootstrapped slopes from quantreg
% figure; histogram(S.ab_boot(:,2));
% this plots the data, the fit, and the bootstrapped fit from quantreg
% figure; plot(t,y,'o'); hold on;
% plot(S.xfit,S.yfit);
% plot(S.xfit,S.yhatci_boot(:,2))
% plot(S.xfit,S.yhatci_boot(:,1))
% 
% print the bootstrapped slope plus or minus 1 stderr
% [S.ab_boot(2)+S.se_boot(2) S.ab_boot(2)-S.se_boot(2)] 
% [S.ab_boot(2)+1.96*S.se_boot(2) S.ab_boot(2)-1.96*S.se_boot(2)]


% % this is an old note not sure
% % prior method, delete if above is considered best
%    if isregular(t,'months')
%       nmonths  = numel(t);
%       t        = years(t-t(1));
%    elseif isdatetime(t)
%       t        = year(t);
%    end
   
end

%  MAKE THE FIGURE

function [h,makeleg,legidx] = updateFigure(useax,showfig,figpos,errorbounds)
   
   % if an axis was provided, use it, otherwise make a new figure
   if not(isaxis(useax))
      if showfig == true
         h.figure = figure('Position',figpos);
      else
         h.figure = figure('Position',figpos,'Visible','off');
      end
      h.ax     = gca;
   else
      h.ax     = useax;
   end
   
   % the legend is parented by the figure, so if the figure contains
   % subplots, i can't just use findobj(gcf,'Type','Legend') to determine
   % if the current plot has a legend already, which i want because I want
   % to add the next trendplot trendline to the existing legend
   % legobj      = findobj(gcf,'Type','Legend');
   
   figchilds   = get(gcf,'Children');
   axobj       = findobj(gcf,'Type','Axes');
   legobj      = findobj(gcf,'Type','Legend');
   numleg      = numel(legobj); % 1 = one legend, 2 indicates a subplot
   numax       = numel(axobj);
   
   % assume we want to append onto an existing legend
   makeleg = false; if numax>numleg || numleg==0; makeleg = true; end
   
   % assume only trendplots exist, each one has data + trend line, so the
   % number of trendlines is numlines/2, unless errorbounds is true
   
   axchildren  = allchild(h.ax);  % get the children to find lines
   numchilds   = numel(axchildren);
   % above here og don't mess
   
   lineobjs    = findobj(axchildren,'type','line');
   patchobjs   = findobj(axchildren,'type','patch');
   errorobjs   = findobj(axchildren,'type','errorbar');
   
   % if only the error bars have handle visibility on, this should work.
   % also this shows that i can figure out how many have handlevis on and
   % use that to determine thislineidx. note, thislineidx is used to set
   % the color order, so repeated calls to trendplot use the same color for
   % the line/patch/errorbar, but it is also used to set the new legend
   % text
   numlines       = numel(lineobjs);
   %thislineidx = numlines+1;
   numpatches     = numel(patchobjs);
   numerrorbars   = numel(errorobjs);

   % if we have one timeseries plotted, there will be two lineobj's (one
   % for the timeseries, and one for the trendline), so we want thislineidx
   % to evaluate to 2, but I think if errorbar is true, it means there will
   % be one line object (the trendline)
   
   % when i added errorbars, it worked to just do thislineidx = numlines+1,
   % until i plotted wihtout errorbarrs, then it didn't work, so I added
   % this:
   if numerrorbars > 0 && numerrorbars == numlines
      thislineidx = numlines+1;
   elseif numerrorbars == 0 && mod(numlines,2) == 0
      thislineidx = numlines/2+1; % should alwasy be two lines per plot
   end

%    % this is the original 
%    if errorbounds == true && mod(numchilds,2) == 1
%       numlines    = (numchilds-1)/2;
%       thislineidx = numlines+1;
%    else
%       numlines    = numel(axchildren)/2;
%       thislineidx = numlines+1;
%    end

   set(h.ax,'ColorOrderIndex',thislineidx);
   
   hold on;
   
   legidx = thislineidx;
   % this version hides the -o lines so the legend shows - lines
%    h.plot   = plot(useax,t,y,'-o','HandleVisibility','off',plotvarargs{:});
%    h.trend  = plot(useax,t,ytrend,'-','Color',h.plot.Color,'LineWidth',1);
%    formatPlotMarkers; 
   
end

%  PLOT TRENDS

function h = plotTrend(h,t,y,yfit,yerr,yci,errorbars,errorbounds,varargs)

   % see formaterrorbar script, might use instead of formatplotmarkers or
   % add the errorbar functionality to that one
   
   % plot errorbounds first
   if errorbounds == true
      
      c  = h.ax.ColorOrder(h.ax.ColorOrderIndex,:);

      Y  = [yci(:,2)' fliplr(yci(:,1)')];
      X  = [t' fliplr(t')];
               
      h.bounds = patch('XData',X,'YData',Y,'FaceColor',c,'FaceAlpha',0.15,...
                  'EdgeColor','none','Parent',h.ax,'HandleVisibility','off'); 
   end
   
   if errorbars == true
      
      % formatPlotMarkers handles edgecolor, facecolor, and marker size
      h.plot   = errorbar(h.ax,t,y,yerr,  'Marker',           'o',      ...
                                          'LineWidth',        1.5,      ...
                                          'LineStyle',        '-',      ...
                                          'MarkerEdgeColor', [.5 .5 .5] );
 
   else  % trendlines
      h.plot   = plot(h.ax,t,y,'-o','LineWidth',2,varargs{:});
   end
         
   h.trend  = plot(h.ax,t,yfit,'-','Color',h.plot.Color,  ...
                  'LineWidth',1,'HandleVisibility','off');
   formatPlotMarkers; 

end


%  DRAW LEGEND

function h = drawLegend(h,ab,legtext,units,alpha,err,makeleg,legidx,precision)
   
   % this is repeated here and in updateFigure
   legobj = findobj(gcf,'Type','Legend');
   
   % only draw a legend if trend units were provided
   % if not(isempty(trendunits))

   %trendtext   = sprintf(['%.2f ' trendunits ],ab(2));
   %mytextbox(trendtext,50,90,'interpreter','tex','fontsize',10);
   
   if isnan(precision)
      prec  = ceil(abs(log10(ab(2))))+1;
   else
      prec  = precision;
   end

   % log10(ab(2)) = the number of zeros to right or left of decimal
   % ceil(log10(ab(2))) = ceil gets you to the digit e.g.:
   % ceil(abs(log10(0.003))) = 3
   % ceil(abs(log10(300))) = 3
   % +1 gets you an extra digit of precision

   if prec>5
      bexp     = floor(log10(abs(ab(2))));
      bbase    = ab(2)*10^-bexp;
      if isnan(alpha)
         trendtxt = sprintf([legtext ' (trend: %.2fe$^{%.2f}$ ' units ...
                        ')'],bbase,bexp                );
      else
         errstr   = num2str(round(100*(1-alpha)));
         
%          trendtxt = sprintf([legtext ' (trend: %.2fe$^{%.2f}'     ...
%             '$\\pm$ %.2f (' errstr '$\\%%$ CI)$ ' units ')'],...
%                      bbase,bexp,err);
                  
         % to turn off the 95% Ci part:
         trendtxt = sprintf([legtext ' (trend: %.2fe$^{%.2f}'     ...
            '$\\pm$ %.2f ' units ')'],bbase,bexp,err);
                  
      end

   else
      if isnan(alpha)
         trendtxt = sprintf([legtext ' (trend: %.' num2str(prec)  ...
                           'f ' units ')'],   ab(2)             );
      else
         errstr   = num2str(round(100*(1-alpha)));
         
%          trendtxt = sprintf([legtext ' (trend: %.' num2str(prec)  ...
%                      'f $\\pm$ %.' num2str(prec) 'f ('      ...
%                      errstr '$\\%%$ CI) ' units ')'],ab(2),err);

         % to turn off the 95% Ci part:
         trendtxt = sprintf([legtext ' (trend: %.' num2str(prec)  ...
                     'f $\\pm$ %.' num2str(prec) 'f ' units ')'],ab(2),err);
                  
      end

   end

   if makeleg == true % isempty(legobj)
     %h.legend    = legend(h.trend,trendtxt,'interpreter','latex');
      h.legend    = legend(h.plot,trendtxt,'interpreter','latex');
   else
      % the current legend will be the first one, not numleg as I expected
      legobj(1).String{legidx}  = trendtxt;
   end

%    end

end