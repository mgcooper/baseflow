function station = stationname(typenamehere)
%STATIONNAME return string 'station' from the bfra basin database
% 
%  Syntax
%  
%  station = bfra.stationname(<tab complete basin name>), returns the station name
%  string as it exists in the bfra basin database
% 
%  stationname = bfra.stationname('ALL_STATIONS'), returns string all 'ALL_STATIONS'
%  which can be passed into other functions that require the 'stationname' keyword
%  argument to return data for all stations. Note: this option does not return
%  all of the stationnames
% 
%  Description
% 
%  the 'stationname' keyword is passed into other functions that require the
%  stationname string as input to load data for that station.
% 
% 
%  See also bfra.loadcalm bfra.loadflow bfra.loadgrace bfra.stationlist

p = inputParser;
p.FunctionName = 'bfra.stationname';
addRequired( p,'typenamehere');
parse(p,typenamehere);
station = p.Results.typenamehere;
   
   