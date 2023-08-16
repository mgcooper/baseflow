function Meta = loadmeta(basinname,varargin)
% LOADMETA load metadata for basin indicated by basinname
% 
% Syntax
% 
%     Meta = loadmeta(basinname,varargin)
% 
% Description
% 
%     Meta = loadmeta(basinname) loads metadata table for basinname.
% 
% See also loadflow, loadcalm, loadbounds
% 
% Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% fast exit if toolbox not configured for data 
if ~isenv('BASEFLOW_DATA_PATH')
   error('BASEFLOW_DATA_PATH environment variable not set')
end

%  PARSE INPUTS
[basinname, version] = parseinputs(basinname, varargin{:});

% load the basin metadata
switch version
   case 'current'
      filebounds = fullfile(getenv('BASEFLOW_DATA_PATH'), 'basins', 'basin_boundaries.mat');
   case 'archive'
      filebounds = fullfile(getenv('BASEFLOW_DATA_PATH'), 'basins', 'basin_boundaries_tmp.mat');
end
load(filebounds,'Meta');

if strcmp(basinname,'ALL_BASINS')    % return all the basins
   return
end
% check for categorical station name
if iscategorical(basinname); basinname = char(basinname); end

% find the flow data
allnames = lower(Meta.name);
istation = ismember(allnames,lower(basinname));
if sum(istation) == 0
   % try station names
   allnames = lower(Meta.station);
   istation = ismember(allnames,lower(basinname));
end
Meta = Meta(istation,:);

end

%% input parser

function [basinname, version] = parseinputs(basinname, varargin)

   validopts = @(x)any(validatestring(x,{'current','archive'}));
   parser = inputParser;
   parser.FunctionName = 'bfra.loadmeta';
   parser.addRequired('basinname', @ischar);
   parser.addOptional('version', 'current', validopts);
   parser.parse(basinname,varargin{:});
   version = parser.Results.version;
end
