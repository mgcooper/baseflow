function tf = ischarlike(x)
   %ISCHARLIKE Return true if input X is a cellstr, char, or string array.
   %
   % Syntax
   %
   %  tf = ISCHARLIKE(X) returns true if X is either a cellstr, char, or string
   %  array 
   %
   % Example
   %
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also islist

   tf = iscellstr(x) | ischar(x) | isstring(x) ;
end
