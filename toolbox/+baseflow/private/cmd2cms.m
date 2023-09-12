function cms = cmd2cms(cmd)
   %CMD2CMS convert cubic meters / second to cubic meters / day
   %
   % inputs:
   %   cfs = array of flow values in cubic meters/second
   %
   % outputs:
   %   cms = array of flow values in cubic meters/second
   %
   % See also:

   cms = cmd./86400;
end