function tf = islinepositive(y)
   %ISLINEPOSITIVE Return true if linear fit to input X has positive slope.
   %
   %  tf = islinepositive(y) fits a straight line to y against its index
   %  and returns true when the fitted slope is positive.
   ab = [ones(size(y)), (1:numel(y))'] \ y;
   tf = ab(2) > 0;
end
