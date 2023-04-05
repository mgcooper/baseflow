function varargout = version()
%VERSION return the version number for the bfra toolbox
% 
%  version()
% 
%  See also
v = '0.1.0';

if nargout == 1
   varargout{1} = v;
else
   disp(v);
end

%  _____    _______   ________      ________
% |  _   \  |   ___|  |   _   \    /   _    \
% | (_)  /  |  |___   |  (_)  |   /   (_)    \
% |-----|   |   ___|  |  __   /   |          |
% |  _  \   |  |      |  | \  \   |    /\    |
% | (_)  \  |  |      |  |  \  \  |   /  \   |
% |______/  |__|      |__|   \__\ |__|    |__|
% 
