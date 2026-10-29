function hrain = plotrain(ax, hmarker, rain, x, y)
   %PLOTRAIN Circle the point-cloud points that have rain.
   %
   %  hrain = plotrain(ax, hmarker, rain, x, y) draws one open magenta
   %  circle in ax at each point (x, y) where rain > 0. The circle size is
   %  the marker size of hmarker plus sqrt(pi*rain^2), so 1 mm of rain
   %  adds the size of a 1 mm circle to the plotted marker. hrain holds
   %  the circle handles, or nan when no point has rain > 0.
   %
   %  ax is the axis to plot into. hmarker is the handle of the plotted
   %  q/dqdt points, which gives the marker size that scales the circles.
   %  x and y are q and -dqdt.
   %
   %  See also: pointcloudplot, plotdqdt

   % add rain. scale the circles such that 1 mm of rain equals the size of
   % the plotted circles. Return nan when no point has rain > 0, because
   % the legend guards of both callers test for nan. NaN rain makes the
   % sum NaN, so the sum test alone misses that case.
   if sum(rain)==0 || ~any(rain>0)
      hrain = nan;
   else

      % scatter is producing pixelated symbols so I use plot instead
      % sz = h.scatter.SizeData + pi.*(rain(rain>0)).^2;
      % scatter(x(rain>0),y(rain>0),sz,'LineWidth',2)

      % this mimics the way scatter scales the circles. Read the size with
      % get, because Octave returns a numeric handle, which takes no dot.
      sz = get(hmarker, 'MarkerSize') + sqrt(pi.*(rain(rain>0)).^2);
      x = x(rain>0);
      y = y(rain>0);

      hold(ax, 'on');

      % Count down so the handle array takes its size on the first pass.
      for n = numel(sz):-1:1
         hrain(n) = plot(ax,x(n),y(n),'o','MarkerSize',sz(n), ...
            'MarkerFaceColor','none','Color','m','LineWidth',1);
      end
   end
end
