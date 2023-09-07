function S = catstructfields(dim, varargin)
   %CATSTRUCTFIELDS Concatenate struct arrays with common field names.
   %
   % S = catstructfields(S1, S2) Catenates structs S1 and S2 along dimension 1
   % S = catstructfields(dim, S1, S2) Catenates structures S1 and S2 along
   % dimension DIM.
   %
   % All fieldnames of S1 must be present in S2. If not, see CATSTRUCTS.
   %
   % See also: catstructs

   % dim = varargin(cellfun(@(s) ~isstruct(s), varargin));
   
   if isstruct(dim) && all(cellfun(@isstruct, varargin))
      varargin = [{dim}, varargin];
      dim = 1;
   end
   
   if isscalar(varargin) && isstruct(varargin{1})
      S = varargin{1};
      return
   end

   F = cellfun(@fieldnames, varargin, 'uni', 0);
   assert(isequal(F{:}),'All structures must have the same field names.')
   T = [varargin{:}];
   S = struct();
   F = F{1};
   for k = 1:numel(F)
      S.(F{k}) = cat(dim,T.(F{k}));
   end
end