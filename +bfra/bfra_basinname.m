function basinname = bfra_basinname(typenamehere)
   p = MipInputParser;
   p.FunctionName = 'bfra_basinname';
   p.addRequired('typenamehere')
   p.parseMagically('caller');
   basinname = typenamehere;
   
   