function tf = islineconvex(y)
   %ISLINECONVEX Return true if linear fit to input X is convex up.
   dy = diff(y);
   ab = [ones(size(dy)), (1:numel(dy))'] \ dy;
   tf = ab(2) < 0;
end
