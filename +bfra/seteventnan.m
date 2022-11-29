%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function  [T,Q,R,Info] = seteventnan()
    T               = [];
    Q               = [];
    R               = [];
    Info.imaxima    = [];
    Info.iminima    = [];
    Info.iconvex    = [];
    Info.icandidate = [];
    Info.ikeep      = [];
    Info.ifirst     = [];   % first non-nan index
    Info.istart     = [];
    Info.istop      = [];
    Info.runlengths = [];
end