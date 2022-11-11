function basinname = basinname(typenamehere)
% BASINNAME return string 'basinname' from the bfra basin database
% 
%  Syntax
%  
%  basinname = bfra.basinname(<tab complete basin name>), returns the basin name
%  string as it exists in the bfra basin database
% 
%  basinname = bfra.basinname('ALL_BASINS'), returns string all 'ALL_BASINS'
%  which can be passed into other functions that require the 'basinname' keyword
%  argument to return data for all basins. Note: this option does not returns
%  all of the basinnames
% 
%  Description
% 
%  the 'basinname' keyword is passed into other functions that require the
%  basinname string as input to load data for that basin.
% 
% 
%  See also bfra.loadcalm bfra.loadflow bfra.loadgrace bfra.stationlist
% 
%  Todo: 'ALL_BASINS' should return all of the basin names, see bfra.stationlist
%  which appends 'ALL_BASINS' to the stationlist for use with loaddata functions

   p              = inputParser;
   p.FunctionName = 'bfra.basinname';
   addRequired( p,'typenamehere');
   parse(p,typenamehere);
   basinname = p.Results.typenamehere;
   
   