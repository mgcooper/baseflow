
function cmd = cms2cmd(cms)

    % convert cubic meters / second to cubic meters / day
    
    % inputs:
    %   cfs = array of flow values in cubic meters/second
    % 
    % outputs:
    %   cms = array of flow values in cubic meters/second

    cmd = cms.*86400;
