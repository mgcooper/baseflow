function tf = isdatelike(x)
tf = isdatetime(x) || (isnumeric(x) && isvector(x));