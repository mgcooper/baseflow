function showdocs(varargin)

   try
      showdemo(varargin{1});
   catch
      if nargin==1
         disp(['Cannot find documentation for ',varargin{1},'.'])
         disp('Opening the baseflow documentaton page.')
      end
      showdemo('bfra_contents.html')
   end

end