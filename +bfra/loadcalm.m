function Calm = loadcalm(basinname,varargin)
%LOADCALM loads calm ALT data for a basin in the Bounds struct

% since I think in terms of basins right now, not calm sites, this accepts
% the basin name not the calm site name

%------------------------------------------------------------------------------
p              = inputParser;
p.FunctionName = 'bfra.loadcalm';
addRequired(p, 'basinname',         @(x)ischar(x));
addOptional(p, 'version','current', @(x)ischar(x));
parse(p,basinname,varargin{:});
version = p.Results.version;
%------------------------------------------------------------------------------

Meta = bfra.loadmeta(basinname,version);

% load the calm data
pathdata = [getenv('USERDATAPATH') 'interface/permafrost/alt/CALM/archive/'];
filedata = [pathdata 'CALM_ALT.mat'];

load(filedata,'Calm','Tcalm');

% find the calm data
if isempty(Meta.sites_calm)
   error('no calm data for this basin')
else
   i1      = find(string(Calm.Properties.VariableNames) == "x1990");
   i2      = find(string(Calm.Properties.VariableNames) == "x2019");
   Dc      = table2array(Calm(Meta.use_calm,i1:i2)); Dc = Dc';
   Calm    = timetable(Dc,'RowTimes',Tcalm);
end
