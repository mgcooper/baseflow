function ax = emptyaxes
   %EMPTYAXES Return empty axes object.
   %
   %  ax = emptyaxes() returns gobjects(0), an empty array of graphics
   %  objects. In Octave, ax is an empty numeric array.
   if isoctave
      ax = [];
      % ax = get(gcf, "currentaxes");
   else
      ax = gobjects(0);
   end
end