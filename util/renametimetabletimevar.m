function T = renametimetabletimevar(T)
   
   dims  = T.Properties.DimensionNames;
      
   if string(dims{1}) ~= "Time"
      T.Properties.DimensionNames{1} = 'Time';
   end