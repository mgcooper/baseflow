function basins = basinlist
%BASINLIST load the list of basins in the bfra database
% 
% Syntax
% 
%     basins = basinlist
% 
% Description
% 
%     basins = basinlist returns a cellstr array of basin names for each basin
%     in the bfra database. The basinlist is used to facilitate auto-completion
%     in various other functions, but also provides users with a reference list
%     of available data.
% 
% See also bfra/functionSignatures.json, basinname
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

load basinlist basins
basins = transpose(['ALL_BASINS', basins]);
