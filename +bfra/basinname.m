function basinname = basinname(typenamehere)
% BASINNAME returns a string 'basinname' from the bfra basin database, which can
% be passed into other functions that require the basinname string in this
% format.

   p              = inputParser;
   p.FunctionName = 'bfra.basinname';
   addRequired( p,'typenamehere');
   parse(p,typenamehere);
   basinname = p.Results.typenamehere;
   
   