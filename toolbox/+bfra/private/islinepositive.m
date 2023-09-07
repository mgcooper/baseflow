function tf = islinepositive(y)
   %ISLINEPOSITIVE Return true if linear fit to input X has positive slope.
   ab = [ones(size(y)), (1:numel(y))'] \ y;
   tf = ab(2) > 0;
end
