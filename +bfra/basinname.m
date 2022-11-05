function basinname = basinname(typenamehere)
% BASINNAME returns a string 'basinname' from the bfra basin database, which can
% be passed into other functions that require the basinname string in this
% format.

   p = MipInputParser;
   p.FunctionName = 'bfra.basinname';
   p.addRequired('typenamehere')
   p.parseMagically('caller');
   basinname = typenamehere;
   
   