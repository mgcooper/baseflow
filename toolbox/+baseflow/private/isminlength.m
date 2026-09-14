function [tf, istart, iend] = isminlength(tf, nmin)
   %ISMINLENGTH Return true for runlengths exceeding minimum length.
   %
   %  [tf, istart, iend] = isminlength(tf, nmin) computes the run lengths
   %  of the input vector tf and returns true where the run length is nmin
   %  or more. istart and iend are the start and end indices of each
   %  stretch where the output tf is true. Adjacent runs that both satisfy
   %  nmin join into one stretch.
   %
   %  Note: runlength counts each NaN as its own run of length 1, because
   %  NaN never equals NaN. Consecutive NaNs therefore never form one run.
   %  Callers set excluded values to NaN to break runs. nmin must be 2 or
   %  more when NaN marks excluded values. An nmin of 0 or 1 marks each NaN
   %  true and joins the stretches on each side of it.
   %
   %  See also: runlength
   rl = runlength(tf);                    % get run lengths
   tf = rl >= nmin;                       % find run lengths >= min length
   istart = find(diff([false; tf]) == 1); % start index of useable events
   iend = find(diff([tf; false]) == -1);  % end index of useable events
end

