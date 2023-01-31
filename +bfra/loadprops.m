function [Dd,A,L,D] = loadprops(basinname,varargin)
%LOADPROPS load basin properties from metadata table
% 
% Syntax
% 
%     [Dd,A,L,D] = loadprops(basinname,varargin)
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

% parse inputs
%------------------------------------------------------------------------------
validopts = @(x)any(validatestring(x,{'current','archive'}));

p                = inputParser;
p.FunctionName   = 'bfra.loadprops';
addRequired(p, 'basinname',         @(x)ischar(x)  );
addOptional(p, 'version','current', validopts      );
parse(p,basinname,varargin{:});
version = p.Results.version;
%------------------------------------------------------------------------------

Meta = bfra.loadmeta(basinname,version);
A  = Meta.area_m2;
Dd = 1000*Meta.Dd;
D  = 0.5;
L  = A*Dd/1000;












