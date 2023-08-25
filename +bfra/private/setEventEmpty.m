function  [T,Q,R,Info] = setEventEmpty()
%SETEVENTEMPTY set recession event to empty array in Events structure
% 
%  [T,Q,R,Info] = setEventEmpty()
% 
% See also: None

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