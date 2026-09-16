function cmd = cms2cmd(cms)
   %cms2cmd convert cubic meters / second to cubic meters / day
   %
   %  cmd = cms2cmd(cms) multiplies the flow values in cms by 86400 to
   %  convert cubic meters per second to cubic meters per day.

   % inputs:
   %   cms = array of flow values in cubic meters/second
   %
   % outputs:
   %   cmd = array of flow values in cubic meters/day

   cmd = cms.*86400;
end