function varargout = closeifpublishing(varargin)
%CLOSEIFPUBLISHING Close figure only if script is being published.
%
%   CLOSEIFPUBLISHING is a wrapper around the CLOSE function. It will only
%   close the specified figure if the script is currently being published,
%   otherwise it will do nothing. CLOSEIFPUBLISHING uses the same input and
%   output arguments as the CLOSE function.
%  
%   See also CLOSE, ISPUBLISHING, SNAPNOWANDCLOSE.

if(ispublishing)
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
