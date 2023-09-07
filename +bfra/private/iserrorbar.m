function tf = iserrorbar(h)
   %ISERRORBAR Return true if input X is an errorbar object.
   if isoctave
      tf = false;
   else
      tf = isa(h,'matlab.graphics.chart.primitive.ErrorBar');
   end
end
