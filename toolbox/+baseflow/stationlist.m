function stations = stationlist()
   %STATIONLIST Return list of stations from the baseflow gage database.
   %
   % Syntax
   %
   %     stations = stationlist()
   %
   % See also: stationname, basinlist

   load stationlist.mat stations
   stations = ['ALL_BASINS'; stations];
end
