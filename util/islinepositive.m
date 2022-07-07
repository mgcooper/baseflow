function tf=islinepositive(y)
    ab=[ones(size(y)),(1:numel(y))']\y;tf=ab(2)>0;
end