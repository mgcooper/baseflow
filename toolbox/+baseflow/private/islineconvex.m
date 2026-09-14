function tf = islineconvex(y)
   %ISLINECONVEX True if the first differences of Y trend downward (concave down).
   %
   %  tf = islineconvex(y) fits a straight line to the first differences of
   %  y against their index and returns true when the fitted slope is
   %  negative.
   dy = diff(y);
   ab = [ones(size(dy)), (1:numel(dy))'] \ dy;
   tf = ab(2) < 0;
end
