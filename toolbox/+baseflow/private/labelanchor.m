function [xa, ya, factor] = labelanchor(a, b, xlims, ylims, factor)
   %LABELANCHOR Anchor a reference-line label inside the axes.
   %
   % Syntax
   %
   %     [xa, ya, factor] = labelanchor(a, b, xlims, ylims, factor)
   %
   % Description
   %
   %     [xa, ya, factor] = labelanchor(a, b, xlims, ylims, factor) returns
   %     the point (xa, ya) on the reference line -dQ/dt = a*Q^b where a
   %     label starts. The anchor sits one factor-th of the y decades above
   %     ylims(1). A line that reaches that height near xlims(1) crowds its
   %     label against the left spine, so the function raises the anchor
   %     until xa clears the inset below. factor 1 anchors the label at the
   %     top of the y range and ends the search, so the loop always ends.
   %
   %     The returned factor says how far the search raised the anchor.
   %
   %     Note: the search moves the anchor right, so it cannot help a label
   %     that runs off the right edge of the axes.
   %
   % See also: plotrefline, plotdqdt

   ndecsy = log10(ylims(2)) - log10(ylims(1));
   ndecsx = log10(xlims(2)) - log10(xlims(1));

   % The label is centered on the anchor in the 'line' style, so an anchor
   % at the left limit puts half the text over the y axis. Start the anchor
   % this fraction of the x decades inside the left limit.
   inset = 1/20;
   xstart = 10^(log10(xlims(1)) + inset * ndecsx);

   % Raise the anchor one step at a time, and stop at the top of the range.
   ya = 10^(log10(ylims(1)) + ndecsy/factor);
   xa = (ya/a)^(1/b);
   while xa < xstart && factor > 1
      factor = factor - 1;
      ya = 10^(log10(ylims(1)) + ndecsy/factor);
      xa = (ya/a)^(1/b);
   end
end
