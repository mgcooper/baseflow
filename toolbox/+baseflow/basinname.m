function basin = basinname(typenamehere)
   % BASINNAME Return string 'basin' from the baseflow basin database.
   %
   % Syntax
   %
   %     basin = basinname(typenamehere)
   %
   % Description
   %
   %     basin = baseflow.basinname(<tab complete basin name>), returns the basin
   %     name string as it exists in the baseflow basin database
   %
   %     basin = baseflow.basinname('ALL_BASINS'), returns string all 'ALL_BASINS'
   %     which can be passed into other functions that require the 'basinname'
   %     keyword argument to return data for all basins. Note: this option does
   %     not returns all of the basinnames
   %
   %     The 'basinname' keyword is passed into other functions that require the
   %     basinname string as input to load data for that basin.
   %
   %
   % See also: baseflow.loadcalm baseflow.loadflow baseflow.loadgrace baseflow.stationlist
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % Todo: 'ALL_BASINS' should return all of the basin names, see baseflow.stationlist
   % which appends 'ALL_BASINS' to the stationlist for use with loaddata functions

   p = inputParser;
   p.FunctionName = 'baseflow.basinname';
   addRequired(p,'typenamehere');
   parse(p,typenamehere);
   basin = p.Results.typenamehere;
end