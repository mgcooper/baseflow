function ax = emptyaxes

if isoctave
   ax = [];
   % ax = get(gcf, "currentaxes");
else
   ax = gobjects(0);
end