function T = renametimetabletimevar(T)
   %RENAMETIMETABLETIMEVAR Rename the time variable in table T to 'Time'.
   %
   %  T = renametimetabletimevar(T)
   %
   % See also:

   dims = T.Properties.DimensionNames;

   if string(dims{1}) ~= "Time"
      T.Properties.DimensionNames{1} = 'Time';
   end
end