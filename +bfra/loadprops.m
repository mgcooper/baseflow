function [Dd,A,L,D] = loadprops(basinname, varargin)
%LOADPROPS load basin properties from metadata table
%
% Syntax
%
%     [Dd,A,L,D] = loadprops(basinname, varargin)
%
% Description
%
%     [Dd,A,L,D] = LOADPROPS(basinname) loads properties for basin with name
%     basinname, Dd is drainage density in 1/km, A is area in m2, L is stream
%     length in m, and D is aquifer thickness in meters
%
% See also loadmeta, loadbounds
%
% Matt Cooper, 03-Dec-2022, https://github.com/mgcooper


% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% fast exit if toolbox not configured for data
if ~isenv('BASEFLOW_DATA_PATH')
   error('BASEFLOW_DATA_PATH environment variable not set')
end

% PARSE INPUTS
[basinname, version] = parseinputs(basinname, varargin{:});

% load the metadata
Meta = bfra.loadmeta(basinname, version);
A  = Meta.area_m2;
Dd = 1000*Meta.Dd;
D  = 0.5;
L  = A*Dd/1000;

end

%% INPUT PARSER
function [basinname, version] = parseinputs(basinname, varargin)

validopts = @(x) any(validatestring(x, {'current', 'archive'}));

p = inputParser;
p.FunctionName = 'bfra.loadprops';

p.addRequired('basinname', @ischar);
p.addOptional('version', 'current', validopts);

p.parse(basinname, varargin{:});

basinname = p.Results.basinname;
version = p.Results.version;

end

