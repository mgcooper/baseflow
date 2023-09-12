function ax = emptyaxes
   %EMPTYAXES Return empty axes object.
   if isoctave
      ax = [];
      % ax = get(gcf, "currentaxes");
   else
      ax = gobjects(0);
   end
end