function q = setconstantnan(q,rmax)

% note: if n=1, then all values will be set nan, so set n = 2
if rmax==1
   disp('rmax = 1, changing to 2, otherwise all values will be removed')
   rmax=2;
end

% set constant sequences of length >rmax true
[~,s,e] = bfra.util.isminlength(q,rmax); 

for i = 1:length(s)
   if s(i)==1
      q(s(i):e(i)) = nan;     % remove the entire series
   else
      q(s(i)+1:e(i)) = nan;   % permit the first constant value
   end
end

end