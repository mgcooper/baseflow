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
