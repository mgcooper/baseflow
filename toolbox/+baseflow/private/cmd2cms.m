function cms = cmd2cms(cmd)
   %CMD2CMS Convert cubic meters / day to cubic meters / second
   %
   % inputs:
   %   cmd = array of flow values in cubic meters/day
   %
   % outputs:
   %   cms = array of flow values in cubic meters/second
   %
   % See also:

   cms = cmd./86400;
end