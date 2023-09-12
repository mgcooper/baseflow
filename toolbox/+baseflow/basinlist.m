function basins = basinlist
   %BASINLIST load the list of basins in the baseflow database
   %
   % Syntax
   %
   %     basins = basinlist
   %
   % Description
   %
   %     basins = basinlist returns a cellstr array of basin names for each
   %     basin in the baseflow database. The basinlist is used to facilitate
   %     auto-completion in various other functions, but also provides users
   %     with a reference list of available data.
   %
   % See also baseflow/functionSignatures.json, basinname
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   load basinlist basins
   basins = transpose(['ALL_BASINS', basins]);
end