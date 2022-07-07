function tf = iserrorbar(h)
   
   tf = false;
   if isa(h,'matlab.graphics.chart.primitive.ErrorBar')
      tf = true;
   end