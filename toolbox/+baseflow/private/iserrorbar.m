function tf = iserrorbar(h)
   %ISERRORBAR Return true if input X is an errorbar object.
   %
   %  tf = iserrorbar(h) returns true if h is a
   %  matlab.graphics.chart.primitive.ErrorBar object. In Octave, tf is
   %  always false.
   if isoctave
      tf = false;
   else
      tf = isa(h,'matlab.graphics.chart.primitive.ErrorBar');
   end
end
