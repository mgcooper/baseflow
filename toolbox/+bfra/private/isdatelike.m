function tf = isdatelike(x)
   %ISDATELIKE Return true if input X is a datetime or datenum-like array.
   tf = isdatetime(x) || (isnumeric(x) && isvector(x));
end
