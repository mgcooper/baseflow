function stations = stationlist
% load(fullfile(fileparts([mfilename '.m']),'stationlist.mat'),'stations');
load 'stationlist.mat' 'stations';
stations = ['ALL_BASINS'; stations];