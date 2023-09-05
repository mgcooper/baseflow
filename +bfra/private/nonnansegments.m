function [S, E, L] = nonnansegments(q, nmin)
   %NONNANSEGMENTS Find start and end indices of complete non-nan segments.
   if nargin < 2
      nmin = 1;
   end
   S = unique([1; find(diff(isnan(q)) == -1)+1]);     % start non-nan segments
   E = unique([find(diff(isnan(q)) == 1);numel(q)]);  % end non-nan segments
   L = E - S + 1;                                     % segment lengths
   S = S(L >= nmin);
   E = E(L >= nmin);
   L = L(L >= nmin);
end