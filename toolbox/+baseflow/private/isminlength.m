function [tf, istart, iend] = isminlength(tf, nmin)
   %ISMINLENGTH Return true for runlengths exceeding minimum length.
   %
   %  [tf, istart, iend] = isminlength(tf, nmin) computes the run lengths
   %  of the input vector tf and returns true where the run length is nmin
   %  or more. istart and iend are the start and end indices of each
   %  stretch where the output tf is true. Adjacent runs that both satisfy
   %  nmin join into one stretch.
   rl = runlength(tf);                    % get run lengths
   tf = rl >= nmin;                       % find run lengths >= min length
   istart = find(diff([false; tf]) == 1); % start index of useable events
   iend = find(diff([tf; false]) == -1);  % end index of useable events
   % NOTE runlength returns a value of 1 for consecutive nan's
end

