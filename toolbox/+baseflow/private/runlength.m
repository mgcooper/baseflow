function rl = runlength(tf)
   %RUNLENGTH get run lengths of consecutive equal values along columns of data
   %
   %  rl = runlength(tf) returns an array rl the size of tf. Each element
   %  of rl holds the length of the run of consecutive equal values that
   %  contains it, computed down each column of tf. tf is a vector or a
   %  matrix of column series. A row vector gives the run lengths of its
   %  column form, returned as a row.
   %
   %  NaN never equals NaN, so each NaN is a run of length 1. For example,
   %  runlength([1;1;NaN;NaN;NaN;2;2]) returns [2;2;1;1;1;2;2]. Callers use
   %  NaN to break runs: isminlength calls runlength, and eventfinder and
   %  setconstantnan call isminlength with NaN at the values they exclude.
   %  Do not merge consecutive NaNs into one run. A long NaN gap would then
   %  pass a minimum length test and join the runs on each side.
   %
   %  See also: isminlength

   % Count a row vector as a column. diff would otherwise work along the
   % row, and the column-wise indexing below needs one series per column.
   sz = size(tf);
   if isrow(tf)
      tf = tf(:);
   end

   diffs = diff(tf) ~= 0;  % find where values change
   ncols = size(diffs, 2); % pad jumps at start and end
   
   diffs = [true(1, ncols); diffs; true(1, ncols)];
   idiff = find(diffs); % linear idx of run starts/stops
   nrows = size(diffs, 1);
   
   i1 = idiff(rem(idiff, nrows) ~= 0);   % rm fake starts in last row
   i2 = idiff(rem(idiff, nrows) ~= 1);   % rm fake stops in first row
   rl = i2-i1; 
   
   assert(sum(rl) == numel(tf));
   
   drl = zeros(size(diffs)); % runlength 'derivative'
   
   drl(i1) = rl; % size must equal size(diffs)
   drl(i2) = drl(i2) - rl;
   
   rl = cumsum(drl(1:end-1, :)); % remove last row and sum
   rl = reshape(rl, sz);         % return a row for a row vector input
end