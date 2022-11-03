function basinname = basinname(typenamehere)
   p = MipInputParser;
   p.FunctionName = 'bfra.basinname';
   p.addRequired('typenamehere')
   p.parseMagically('caller');
   basinname = typenamehere;
   
   