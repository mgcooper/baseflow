%% Baseflow Recession Analysis Examples

% The purpose of this example document is to demonstrate use-cases for each
% function in the bfra toolbox. The emphasis is on toolbox breadth. Deeper
% understanding of individual toolbox functions is communicated in the function
% documention and extended example docs.

%% Preparing data

clean % remove eventually

% The first step to use the basefow toolbox is to prepare a dataset of daily
% streamflow observations for a river catchment. There are many excellent
% software packages available to automate the process of data retrieval. For
% this example, we will use observations of daily streamflow for the Kuparuk
% River basin in Northern Alaska. These data were provided by the United States
% Geological Survey, recorded at streamflow gage 1596000 on the Kuparuk River.
% The data can be downloaded from
% https://waterdata.usgs.gov/monitoring-location/15896000. 
% For this example, we will use the included sample dataset.


% Set the sitename
sitename = bfra.basinname('KUPARUK R NR DEADHORSE AK');




%% Loading data into the workspace

% load streamflow data for the test basin
load('data/dailyflow.mat','T','Q','R');

%% Preparing data for analysis

% there are two 
opts.Events = bfra.setopts('events');
opts.Fits   = bfra.setopts('fits','drainagearea',A);

%% Setting user-defined parameters

%% Detect recession events

%% Fit recession events to estimate recession parameters

%% Get help

% to get help for a local or nested function:
help(['bfra.getevents' filemarker 'updateinfo'])

% to debug a local or nested function:
dbstop in bfra.getevents at updateinfo
dbstop in bfra.getevents>updateinfo