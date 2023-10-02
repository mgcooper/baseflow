function vec = struct2vec(S, fields, shape)
   %STRUCT2VEC Concatenate scalar struct fields into a single column vector.
   %
   %  vec = STRUCT2VEC(S, fields) takes a scalar struct `S` and a cell array of
   %  fieldnames `fields`, then concatenates the vectors in the specified fields
   %  into a single column vector.
   %
   %  Note: The function assumes all fields contain vectors of doubles.
   %
   %    % Example with row vectors:
   %    S.a = [1, 2, 3];
   %    S.b = [4, 5];
   %    S.c = [6, 7, 8, 9];
   %    vec = struct2vec(S, {'a', 'c', 'b'})
   %    % vec will be [1 2 3 6 7 8 9 4 5]
   %
   %    % Specify the output shape as 'column':
   %    vec = struct2vec(S, {'a', 'c', 'b'}, 'column')
   %    % vec will be [1; 2; 3; 6; 7; 8; 9; 4; 5]
   %
   %    % Example with column vectors:
   %    S.a = [1; 2; 3];
   %    S.b = [4; 5];
   %    S.c = [6; 7; 8; 9];
   %    vec = struct2vec(S, {'a', 'c', 'b'})
   %    % vec will be [1; 2; 3; 6; 7; 8; 9; 4; 5]
   %
   %    % Specify the output shape as 'row':
   %    vec = struct2vec(S, {'a', 'c', 'b'}, 'row')
   %    % vec will be [1 2 3 6 7 8 9 4 5]
   %
   %    % Example with mixed shapes:
   %    S.a = [1, 2, 3]; % row
   %    S.b = [4; 5]; % column
   %    S.c = [6, 7; 8, 9]; % matrix
   %    vec = struct2vec(S, {'a', 'c', 'b'})
   %    % vec will be [1; 2; 3; 6; 7; 8; 9; 4; 5] - defaults to column
   %
   %    % Example with shape='column':
   %    vec = struct2vec(S, {'a', 'c', 'b'}, 'column')
   %    % vec will be [1; 2; 3; 6; 8; 7; 9; 4; 5]. Note the order of S.c here
   %    % differs from the previous examples because the elements of S.c are
   %    % concatentated in column-major order.
   %
   %    % Example with shape='row':
   %    vec = struct2vec(S, {'a', 'c', 'b'}, 'row')
   %    % vec will be [1 2 3 6 8 7 9 4 5]. Note the order of S.c here is the same
   %    % as the example above - the output is a row but the elements are
   %    % concatenated in column-major. Preserving rows in the input is not
   %    % currently supported.
   %
   % See also: STRUCT2CELL, EXTRACTFIELD, CELLFUN, VERTCAT

   % Original name catfields, renamed struct2vec

   if nargin < 3
      % If all fields are either columns or rows this will return the same.
      fnc = @(f) S.(f);
   else
      switch shape
         case 'column'
            fnc = @(f) S.(f)(:);
         case 'row'
            fnc = @(f) S.(f)(:)';
         otherwise
            error('Invalid shape argument. Choose from "row" or "column".')
      end
   end

   % Flatten the cell array to a vector.
   try
      % This works for all cases above except nargin < 3 with mixed rows/cols.
      vec = cellflatten(cellfun(fnc, fields, 'Uniform', false));
   catch
      % This means there are mixed rows/columns, revert to column output.
      fnc = @(f) S.(f)(:);
      vec = cellflatten(cellfun(fnc, fields, 'Uniform', false));
   end
end

function V = cellflatten(C)
   %CELLFLATTEN flatten cell array
   try
      V = horzcat(C{:});
   catch
      V = vertcat(C{:});
   end
end


% % NOTES:
%    % Use cellfun to ensure the vector is comprised of each field in order.
%    cellvec = cellfun(@(f) S.(f)(:), fields, 'UniformOutput', false);
%
%    % cellvec is a 1xN cell array, with N = numel(fields). If all fields of S are
%    % row vectors, then each element of cellvec is a row vector, and horzcat
%    % works. If all fields of S are column vectors, then each element of cellvec
%    % is a column vector, and vertcat works.
%    cellvec = cellflatten(cellfun(@(c) c(:), cellvec, 'un', 0));
%    vec = [cellvec{:}];
%
%    % This is what cellflatten does:
%    try
%       vec = vertcat(cellvec{:});
%    catch
%       vec = horzcat(cellvec{:})';
%    end

%    % This method does not preserve the original order of the vectors.
%    vec = struct2cell(S);
%    [~, loc] = ismember(fieldnames(S), fields);
%    vec = vec(loc(loc>0));
%    % here would need to reoreder vec by loc
%    vec = vertcat(vec{:});
