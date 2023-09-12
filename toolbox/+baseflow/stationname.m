function station = stationname(typenamehere)
   %STATIONNAME Return string 'station' from the baseflow basin database.
   %
   %  Syntax
   %
   %  station = baseflow.stationname(<tab complete basin name>), returns the station
   %  name string as it exists in the baseflow basin database
   %
   %  stationname = baseflow.stationname('ALL_STATIONS'), returns string all
   %  'ALL_STATIONS' which can be passed into other functions that require the
   %  'stationname' keyword argument to return data for all stations. Note: this
   %  option does not return all of the stationnames
   %
   %  Description
   %
   %  the 'stationname' keyword is passed into other functions that require the
   %  stationname string as input to load data for that station.
   %
   %
   %  See also: baseflow.loadcalm baseflow.loadflow baseflow.loadgrace baseflow.stationlist

   p = inputParser;
   p.FunctionName = 'baseflow.stationname';
   addRequired( p,'typenamehere');
   parse(p,typenamehere);
   station = p.Results.typenamehere;
end
