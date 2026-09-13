function [S, E, L] = nonnansegments(x, nmin, option)
   %NONNANSEGMENTS Find start and end indices of complete non-nan segments.
   %
   %  [S, E, L] = nonnansegments(x, nmin) returns the start indices S, end
   %  indices E, and lengths L of the non-nan segments of x. It returns only
   %  segments of length nmin or more. nmin defaults to 1.
   %
   % [S, E, L] = nonnansegments(x, nmin, option)
   %
   %  Inputs
   %     X - data. If X is a vector, S, E, L are returned as numeric arrays.
   %     If X is a matrix with >1 column, the algorithm operates on each column
   %     of X and returns S, E, L as cell arrays. If X is a cell array, the
   %     algorithm operates on each element, but currently assumes each element
   %     is a vector.
   %
   %     NMIN - minimum number of non-nan values to be returned as a valid
   %     segment; segments shorter than nmin are removed (default 1)
   %
   %     OPTION - 'any', 'each', 'all' (option not currently implemented  -
   %     don't supply a value)
   %
   % See also:

   if nargin < 3
      option = 'any'; % each?
   end
   if nargin < 2
      nmin = 1;
   end

   if iscell(x)
      % This case assumes each element of x is a vector.
      [S, E, L] = cellfun(@(x) processOneVector(x, nmin), x, 'Uniform', 0);
   else
      if isvector(x)
         [S, E, L] = processOneVector(x, nmin);

      elseif ismatrix(x)

         [S, E, L] = arrayfun(@(col) processOneVector(x(:, col), nmin), ...
            1:size(x, 2), 'Uniform', 0);

         % Identically:
         % for n = size(x, 2):-1:1
         %    [S{n}, E{n}, L{n}] = processOneVector(x(:, n), nmin);
         % end
      end
   end

   % TODO: if the caller passes multiple vectors, return S, E where all vectors
   % are non-nan. It would also be good to allow multi-dimensional input. For
   % example, in fillplot, x and y are 1xN, but err is 2xN, and I want S, E
   % where all of them are non-nan.
   switch option
      case 'all'
         % This is not right: the code needs S and E for each all-nan segment.
         % Handle this in the calling function instead.
         % S = unique(S);
         % E = unique(E);
      otherwise
   end

   % Notes on matrix-wise input. First, the easiest way to combine the methods
   % above and support non-vector cell elements is to cast non-cell input to
   % cell and call cellfun for every case. cellfun would then call a subfunction
   % processOneElement, which would hold the if/elseif vector/matrix logic.

   % However, while adding the vector/matrix logic, I tried two methods, and
   % I document them here. First, without a vector/matrix distinction,
   % processOneVector works with matrices, but it returns the linear indices
   % of all non-nan segments. You can convert those to row/col with ind2sub,
   % or handle them in the calling function. This causes problems when the
   % columns are independent samples that do not share identical start/stop
   % ends. processOneVector treats the whole matrix as one linear vector, so
   % segments "wrap around" columns.

   % Second, to handle that, I initially looped over the columns of X without
   % an if-else. This works for both vectors and matrices, but if and only if
   % each column has the same NUMBER OF start/stops.
   %
   % So I added the if-else. For matrix-wise X, I assign S and E to cell
   % arrays.

   % Another way to handle matrix-wise X without a loop:
   % [row, col] = ind2sub(size(x), S)

end

function [S, E, L] = processOneVector(x, nmin)
   %PROCESSONEVECTOR Segment one vector and filter by minimum length.

   % Remove leading and trailing nan's. The shared private helpers take a
   % time vector and a data vector; pass x as both and keep the first output.
   x = rmtrailingnans(x(:), x(:));
   [x, ~, ~, si] = rmleadingnans(x(:), x(:));

   % An all-nan vector has no segments. Return empty columns so the minimum
   % length filter below does not index the empty S and E with a scalar L.
   if isempty(x)
      S = zeros(0, 1);
      E = zeros(0, 1);
      L = zeros(0, 1);
      return
   end

   % Find start and stop indices of non-nan segments.
   n = isnan(x(:));
   S = [1; find(diff(n) == -1) + 1];         % start non-nan segments
   E = [find(diff(n) == 1); numel(x)];       % end non-nan segments
   L = E - S + 1;                            % segment lengths

   % Shift S and E by the number of leading nan's removed
   S = S + si - 1;
   E = E + si - 1;

   % Remove segments shorter than nmin (eventfinder depends on this). The
   % matfunclib source comments out these lines and ignores nmin, although
   % its help describes this filter.
   S = S(L >= nmin);
   E = E(L >= nmin);
   L = L(L >= nmin);

   % % I think this replaces the logic above and might be clearer, but it won't
   % capture leading/trailing nans either
   % ok = ~isnan(x);
   % S = find(diff([0, ok]) == 1);
   % E = find(diff([ok, 0]) == -1);

   % I think this works with leading and trailing nans
   % S = find(diff([NaN, x]) ~= 0 & ~isnan(x));
   % E = find(diff([x, NaN]) ~= 0 & ~isnan(x));

end

% function [s, e] = startendnonnan(x)
%    n = isnan(x(:));
%    s = find(~n & [true; n(1:end-1)]);
%    e = find(~n & [n(2:end); true]);
%
%    % [x(:) ~n [true; n(1:end-1)]] % starts
%    % [x(:) ~n [n(2:end); true]] % ends
% end
