function varargout = version(option)
   %VERSION return the version number for the baseflow toolbox
   %
   %  v = version()
   %
   % See also:
   v = '1.2.0';

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
      % The banner carries the version twice. These two slots of two
      % characters, the major number beside the v and the minor and patch
      % digits below it, are built from v, so they cannot fall behind it.
      % The large letters to the right are drawn art: a release that
      % changes a digit there redraws those four rows by hand.
      number = sscanf(v, '%d.%d.%d');
      majorslot = fitslot(sprintf('v%d', number(1)));
      minorslot = fitslot(sprintf('%d%d', number(2), number(3)));

      home
      disp(' _______                        ___  __                     ')
      disp('|   _   \.---.-..-----..-----..''  _||  |.-----..--.--.--.  ')
      disp(['|.  ' majorslot '  /|  _  ||__ --||  -__||   _||  ||  _  ||  |  |  |   '])
      disp('|.  _   \|___._||_____||_____||__|  |__||_____||________|   ')
      disp(['|:  ' minorslot '   \              ____        ______      ______      '])
      disp('|::.. .  /   .--.--.   |_   |      |__    |    |      |     ')
      disp('`-------''    |  |  |__  _|  |_  __  ___|  | __ |  --  |    ')
      disp('              \___/|__||______||__||______||__||______|     ')
   end
end

function slot = fitslot(txt)
   %FITSLOT Fit text to the two characters a banner slot holds.
   %
   % A version part of two or more digits would push the art out of line,
   % so pad a short part and cut a long one.
   slot = sprintf('%-2s', txt);
   slot = slot(1:2);
end
