function tf = iserrorbar(h)
   if isoctave
      tf = false;
   else
      tf = isa(h,'matlab.graphics.chart.primitive.ErrorBar');
   end
end