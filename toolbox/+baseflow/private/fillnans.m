function q = fillnans(q,fmax)
   %FILLNANS fill interior sequences of nan values of length <= fmax
   %
   %  q = fillnans(q, fmax) fills the interior nan runs in vector q with
   %  spline interpolation (fillmissing). q can be a row or column vector.
   %  An interior nan run has a non-nan value before and after it.
   %  fillnans fills an interior run when its length is fmax or less and
   %  leaves longer runs unchanged. It does not fill leading or trailing
   %  nan runs, so it never extrapolates. The spline for each run uses the
   %  two non-nan segments on either side of the run.

   % this is hard to follow but it works. it finds the nan segments <= fmax in
   % length and then fills them. the part that's hard to follow is that it
   % also finds the indices of the maximum number of non-nan elements
   % bracketing the missing segment

   % The column form of isnan keeps s and e column vectors for row vector
   % input. s and e index q linearly, so q keeps its shape.
   isn = isnan(q(:));

   % Pad isn with true on both ends so each non-nan segment has one start
   % and one end, also when q starts or ends with nan.
   % mgc 8/12/21 nl should find nans of length <= nmax, not ==
   s   = find(diff([true; isn])==-1);          % start non-nan segments
   e   = find(diff([isn; true])==1);           % end non-nan segments
   nl  = find((s(2:end)-e(1:end-1)-1)<=fmax);  % nans of length nmax on s/e
   ni  = e((s(2:end)-e(1:end-1)-1)<=fmax)+1; % nans of length nmax on q
   %nl  = find((s(2:end)-e(1:end-1))==fmax+1);  % nans of length nmax on s/e
   %ni  = e((s(2:end)-e(1:end-1))==(fmax+1))+1; % nans of length nmax on q

   % Each gap between segments nl(i) and nl(i)+1 is an interior nan run.
   % Leading and trailing runs lie outside every segment pair, so the loop
   % never fills them.
   for i = 1:length(ni)
      si       = s(nl(i));                    % start of segment
      ei       = e(nl(i)+1);                  % end of segment
      q(si:ei) = fillmissing(q(si:ei),'spline');
   end
end
