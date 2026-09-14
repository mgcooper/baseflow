function q = setconstantnan(q,rmax)
   %SETCONSTANTNAN Set constant-valued runlengths of RMAX or more nan.
   %
   %  q = setconstantnan(q, rmax) finds each stretch of q in which every
   %  element belongs to a constant run of rmax or more values. Adjacent
   %  qualifying runs form one stretch. The function sets each stretch nan
   %  but keeps its first value, unless the stretch starts the series. It
   %  changes an rmax of 1 to 2 so it does not remove the whole series.

   % note: if n=1, then all values will be set nan, so set n = 2
   if rmax==1
      disp('rmax = 1, changing to 2, otherwise all values will be removed')
      rmax=2;
   end

   % set constant sequences of length >=rmax true
   [~,s,e] = isminlength(q,rmax);

   for i = 1:length(s)
      if s(i)==1
         q(s(i):e(i)) = nan;     % remove the entire series
      else
         q(s(i)+1:e(i)) = nan;   % permit the first constant value
      end
   end
end

