function varargout = snapnowandclose(varargin)
   %SNAPNOWANDCLOSE Call SNAPNOW and CLOSE only if script is being published.
   %
   %   SNAPNOWANDCLOSE will call SNAPNOW followed by CLOSE, but only if the
   %   script is currently being published. Othewrise, it will do nothing.
   %   CLOSEIFPUBLISHING uses the same input and output arguments as the CLOSE
   %   function.
   %
   %   See also CLOSE, SNAPNOW, ISPUBLISHING, CLOSEIFPUBLISHING.

   if(ispublishing)
      snapnow
      [varargout{1:nargout}] = close(varargin{:});
   end

end

function tf = ispublishing()
   %ISPUBLISHING True if this script is currently being published.
   %   ISPUBLISHING returns 1 if this script is currently being published
   %   using the PUBLISH function, and 0 otherwise.
   %
   %   See also SNAPNOWANDCLOSE, CLOSEIFPUBLISHING

   % Get the function call stack.
   db = dbstack;

   % Collect the list of function names.
   names = {db(:).name};

   % Search for both 'publish' and 'mdbpublish'.
   tf = ismember('publish',names) && ismember('mdbpublish',names);
end
