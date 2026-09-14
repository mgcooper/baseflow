function tf = isdatelike(x)
   %ISDATELIKE Return true if input X is a datetime or datenum-like array.
   %
   %  tf = isdatelike(x) returns true if x is a datetime array or a numeric
   %  vector. isdatelike treats a numeric vector as a possible datenum vector.
   tf = isdatetime(x) || (isnumeric(x) && isvector(x));
end
