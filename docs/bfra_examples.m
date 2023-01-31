%% Baseflow Recession Analysis Examples

% The purpose of this example document is to demonstrate use-cases for each
% function in the bfra toolbox. The emphasis is on toolbox breadth. Deeper
% understanding of individual toolbox functions is communicated in the function
% documention and extended example docs.

% to get help for a local or nested function:
help(['bfra.getevents' filemarker 'updateinfo'])

% to debug a local or nested function:
dbstop in bfra.getevents at updateinfo
dbstop in bfra.getevents>updateinfo

%% Selecting a study area

clean

% Get a list of all basins in the baseflow database.
basinlist = bfra.basinlist;

% Get a list of all streamflow gages in the baseflow database.
stationlist = bfra.stationlist;

% Load the basin/station metadata from the database. The function loadmeta accepts
% any station name in stationlist as input or the special 'ALL_BASINS' option
% that returns all data.
Meta = bfra.loadmeta('ALL_BASINS');

% Load the basin boundaries. Note that Meta is also returned as the second
% output of bfra.loadbounds, bfra.loadflow, and bfra.loadcalm
Basins = bfra.loadbasins('ALL_BASINS','projection','geo');

% Make a map of all the basins in the database. Note: bfra.mapbasins(Basins)
% with no input options will map the face color of the basin boundary polygons
% to the permafrost extent probability value in Meta.perm_mean. Plotting is very
% slow for all >1000 basins. Set facemapping=false to plot the basins as simple
% outlines, or facemapping=true to see the polygons mapped to permafrost extent.
hbasins = bfra.mapbasins(Basins,'facemapping',false);

% make a map of all the streamflow gages in the database
hgages = bfra.mapgages(Meta.lat,Meta.lon);

% select one basin to study. use tab-completion to see the same basins in
% basinlist from the prior step as valid inputs to the basinname function.
sitename = bfra.basinname('KUPARUK R NR DEADHORSE AK');

% load streamflow data for the test basin


%% Acquiring data

% the baseflow toolbox includes functions to acquire streamflow and
% precipipitation data.

% load rainfall data

%% Loading data into the workspace

%% Preparing data for analysis

%% Setting user-defined parameters

%%