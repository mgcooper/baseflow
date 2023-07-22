function ax = emptyaxes

if bfra.util.isoctave
   ax = [];
%    ax = get(gcf, "currentaxes");
else
   ax = gobjects(0);
end