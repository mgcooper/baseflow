function tf = islineconvex(y)
   dy = diff(y);
   ab = [ones(size(dy)), (1:numel(dy))'] \ dy;
   tf = ab(2) < 0;
end