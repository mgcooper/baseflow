function stations = stationlist
   %STATIONLIST Return list of stations from the bfra basin database.
   %
   %
   % See also: stationname

   % load(fullfile(fileparts([mfilename '.m']),'stationlist.mat'),'stations');
   load 'stationlist.mat' 'stations';
   stations = ['ALL_BASINS'; stations];
end