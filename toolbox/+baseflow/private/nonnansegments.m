function [S, E, L] = nonnansegments(x, nmin, option)
   %NONNANSEGMENTS Find start and end indices of complete non-nan segments.
   %
   %  [S, E, L] = nonnansegments(x) returns the start indices S, end indices
   %  E, and lengths L of the non-nan segments of x as column vectors.
   %
   %  [S, E, L] = nonnansegments(x, nmin) returns only segments of length
   %  nmin or more. nmin defaults to 1.
   %
   %  [S, E, L] = nonnansegments(x, nmin, option) sets how a matrix x, or
   %  each matrix element of a cell array x, is segmented. option has no
   %  effect on a vector x or on a vector element of a cell array x.
   %
   %  Inputs
   %     X - data. If X is a vector, S, E, L are numeric column vectors. If X
   %     is a matrix that is not a vector, OPTION sets the output. If X is a
   %     cell array, the algorithm segments each element as a vector or as a
   %     matrix and returns S, E, L as cell arrays the size of X. Each cell of
   %     S, E, L holds the output for that element of X. For example, a
   %     matrix element with OPTION 'each' gives a cell that holds
   %     per-column cell arrays. Leading and trailing nans are allowed.
   %
   %     NMIN - minimum number of non-nan values to be returned as a valid
   %     segment; segments shorter than nmin are removed (default 1)
   %
   %     OPTION - segmentation of a matrix X (default 'each'). For a cell
   %     array X, these rules apply to each matrix element of X:
   %        'each' - segment each column of X on its own and return S, E, L
   %                 as 1-by-size(X, 2) cell arrays.
   %        'all'  - return numeric S, E, L of the row segments where every
   %                 column of X is non-nan.
   %        'any'  - return numeric S, E, L of the row segments where at
   %                 least one column of X is non-nan.
   %
   %  Example
   %     % Segments where x, y, and both rows of a 2-by-N err are non-nan:
   %     [S, E] = nonnansegments([x(:), y(:), err.'], 1, 'all');
   %
   % See also:

   % Set defaults. The 'each' default keeps per-column cell output for a
   % matrix. validatestring rejects an unknown option before any branch.
   if nargin < 3
      option = 'each';
   end
   if nargin < 2
      nmin = 1;
   end
   option = validatestring(option, {'each', 'all', 'any'}, mfilename);

   % Cast non-cell input to a one-element cell. Then one algorithm segments
   % a vector, a matrix, and each element of a cell array in the same way.
   wascell = iscell(x);
   if ~wascell
      x = {x};
   end
   [S, E, L] = cellfun(@(v) processOneElement(v, nmin, option), x, ...
      'Uniform', 0);

   % Return non-cell input in its own form: numeric S, E, L for a vector or
   % for 'all' and 'any', and per-column cell arrays for 'each'.
   if ~wascell
      S = S{1};
      E = E{1};
      L = L{1};
   end
end

function [S, E, L] = processOneElement(x, nmin, option)
   %PROCESSONEELEMENT Segment one vector or matrix under the option rule.
   %
   %  X is a vector or a matrix, not a cell array. A vector returns numeric
   %  column vectors S, E, L for every option. A matrix returns per-column
   %  cell arrays for 'each', and numeric column vectors of the row segments
   %  for 'all' and 'any'. processOneVector does the segmentation.

   % A vector has one nan mask, so every option gives the same result.
   if isvector(x)
      [S, E, L] = processOneVector(isnan(x), nmin);
      return
   end

   % Note: segment a matrix by rows or by columns, never as x(:). The linear
   % indices of x(:) let a segment wrap from the end of one column into the
   % next.
   switch option
      case 'each'
         % Columns are independent samples with different numbers of
         % segments, so return one cell per column.
         [S, E, L] = arrayfun( ...
            @(col) processOneVector(isnan(x(:, col)), nmin), ...
            1:size(x, 2), 'Uniform', 0);
      case 'all'
         % A row is missing when any column is nan.
         [S, E, L] = processOneVector(any(isnan(x), 2), nmin);
      case 'any'
         % A row is missing only when every column is nan.
         [S, E, L] = processOneVector(all(isnan(x), 2), nmin);
   end
end

function [S, E, L] = processOneVector(n, nmin)
   %PROCESSONEVECTOR Segment one nan mask vector and filter by minimum length.
   %
   %  N is a logical vector that is true where the data is nan. S, E, and L
   %  are column vectors. An all-nan mask returns zeros(0, 1) for all three.

   % Find start and stop indices of non-nan segments. A segment starts at a
   % non-nan value after a nan or at the first element, and ends at a non-nan
   % value before a nan or at the last element. The padding handles leading
   % and trailing nans without trimming them.
   n = n(:);
   S = find(~n & [true; n(1:end-1)]);        % start non-nan segments
   E = find(~n & [n(2:end); true]);          % end non-nan segments

   % find returns 0-by-0 for a scalar nan mask. Reshape S and E so that
   % all-nan input of any length returns zeros(0, 1).
   S = reshape(S, [], 1);
   E = reshape(E, [], 1);
   L = E - S + 1;                            % segment lengths

   % Remove segments shorter than nmin (the bfra eventfinder depends on this).
   S = S(L >= nmin);
   E = E(L >= nmin);
   L = L(L >= nmin);
end
