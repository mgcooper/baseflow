%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% get run lengths of consecutive equal values along columns of data
function rl = runlength(tf)
    diffs   = diff(tf)~=0;                  % find where values change
    ncol    = size(diffs,2);                % pad jumps at start and end
    diffs   = [true(1,ncol);diffs;true(1,ncol)]; 
    idiff   = find(diffs);                  % linear idx of run starts/stops
    nrow    = size(diffs,1);
    i1      = idiff(rem(idiff,nrow)~=0);    % rm fake starts in last row
    i2      = idiff(rem(idiff,nrow)~=1);    % rm fake stops in first row
    rl      = i2-i1; assert(sum(rl)==numel(tf));
    drl     = zeros(size(diffs));           % runlength 'derivative'
    drl(i1) = rl;                           % size must equal size(diffs)
    drl(i2) = drl(i2)-rl;
    rl      = cumsum(drl(1:end-1,:));       % remove last row and sum
end