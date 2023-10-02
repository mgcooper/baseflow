function varargout = version(option)
   %VERSION return the version number for the baseflow toolbox
   %
   %  v = version()
   %
   % See also:
   v = '0.1.0';

   if nargin < 1
      option = 'verbose';
   else
      validatestring(option, {'silent', 'verbose'}, mfilename, 'OPTION', 1);
   end

   if nargout == 1
      varargout{1} = v;
   else
      disp(v);
   end

   if strcmp(option, 'verbose')
      home
      disp(' _______                        ___  __                     ')
      disp('|   _   \.---.-..-----..-----..''  _||  |.-----..--.--.--.  ')
      disp('|.  v1  /|  _  ||__ --||  -__||   _||  ||  _  ||  |  |  |   ')
      disp('|.  _   \|___._||_____||_____||__|  |__||_____||________|   ')
      disp('|:  00   \              ____        ______      ______      ')
      disp('|::.. .  /   .--.--.   |_   |      |      |    |      |     ')
      disp('`-------''    |  |  |__  _|  |_  __ |  --  | __ |  --  |    ')
      disp('              \___/|__||______||__||______||__||______|     ')
   end
end
