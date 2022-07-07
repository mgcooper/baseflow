function S = catStructFields(dim, varargin)
    
    F = cellfun(@fieldnames,varargin,'uni',0);
    assert(isequal(F{:}),'All structures must have the same field names.')
    T = [varargin{:}];
    S = struct();
    F = F{1};
    for k = 1:numel(F)
        S.(F{k}) = cat(dim,T.(F{k}));
    end
    
%   % for reference, this is how two struct's would be catted
%   f = fieldnames(S1); % assume fieldnames are identical in S1 and S2
%   S = cell2struct(cellfun(@vertcat,struct2cell(S1),       ...
%                         struct2cell(S2),'uni',0),f);
%   % or like this:
%     for i = 1:numel(f)    
%         S.(f{i}) = [S1.(f{i});S2.(f{i})];
%     end
    
end