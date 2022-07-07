function [tf,istart,iend]  = isminlength(tf,nmin)
    rl      = runlength(tf);                % get run lengths
    tf      = rl>=nmin;                     % find run lengths > min length
    istart  = find(diff([false;tf])==1);    % start index of useable events
    iend    = find(diff([tf;false])==-1);   % end index of useable events
end

function rl = runlength(tf)
    % get run lengths of consecutive equal values along columns of data
    
    diffs   = diff(tf)~=0;    % find where values change
    ncol    = size(diffs,2);    % pad implicit jumps at start and end
    diffs   = [true(1,ncol);diffs;true(1,ncol)]; 
    idiff   = find(diffs);      % linear indices of starts and stops of runs
    nrow    = size(diffs,1);
    i1      = idiff(rem(idiff,nrow)~=0); % remove fake starts in last row
    i2      = idiff(rem(idiff,nrow)~=1); % remove fake stops in first row
    rl      = i2-i1;
    assert(sum(rl)==numel(tf));

    % runlength 'derivative', size must equal size(diffs) for valid indices
    dRL     = zeros(size(diffs)); 
    dRL(i1) = rl;
    dRL(i2) = dRL(i2)-rl;
    rl      = cumsum(dRL(1:end-1,:)); % remove last row and sum run lengths

end
