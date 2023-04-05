function  [T,Q,R,Info] = seteventnan()
%SETEVENTNAN set recessoin event nan in Events structure
% 
%  [T,Q,R,Info] = seteventnan()
% 
% See also

T               = [];
Q               = [];
R               = [];
Info.imaxima    = [];
Info.iminima    = [];
Info.iconvex    = [];
Info.icandidate = [];
Info.ikeep      = [];
Info.istart     = [];
Info.istop      = [];
Info.runlengths = [];
Info.ifirst     = [];  % first non-nan index
Info.datalength = [];  % total number of values