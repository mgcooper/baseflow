%% Estimating recession constants with the point cloud method

%%% Introduction
% In this example, we use baseflow recession analysis to investigate daily
% streamflow data measured in the Kuparuk River Basin on the North Slope of
% Alaska. Observations of daily streamflow are provided by the United States
% Geological Survey, recorded at streamflow gage 1596000. The data are included
% in the |data/| folder as a sample dataset with this toolbox, and can be
% downloaded from https://waterdata.usgs.gov/monitoring-location/15896000.
%% 
% The example demonstrates how to detect recession events, and then estimate
% recession constants _a_ and _b_ using the "point cloud" method.

%%% Preparing data for analysis
% The minimum required information to fit recession constants is a timeseries of
% daily streamflow. The drainage area of the upstream river basin, and values
% for drainage density, stream channel length, basin slope, and aquifer
% thickness are used by other functions in the toolbox, and are explored in
% other examples.

%%
% The |basinname| function returns a pre-formatted string from a database of 
% streamflow gages included with the toolbox in |data/stationlist.mat|. The
% station names in the database are the official USGS station names. Use
% tab-completion to set the argument to the |basinname| function.
% 
% Set the sitename. 
sitename = bfra.basinname('KUPARUK R NR DEADHORSE AK');

%%
% Load streamflow data for the test basin into the workspace. In the sample
% dataset, the variable |T| is _time_, |Q| is _discharge_, and |R| is
% _rainfall_.
load('data/dailyflow.mat','T','Q','R');
%%
% Plot one year of the data. Use the toolbox helper functions to pass
% pre-formatted latex strings to the ylabel. Set the y-axis to log scale to see
% the shape of the recession curve in more detail.
t1 = datetime(1992,6,1);
t2 = datetime(1992,12,1);
figure('Position',[0 0 350 200]); ax = gca;
H = hyetograph(T,Q,R,t1,t2,'units',{'m3 d-1','mm d-1'},'ax',ax);

%%% Detecting recession events from timeseries of daily streamflow
% The toolbox supports three main tasks: event detection, event curve-fitting,
% and parameter distribution fitting. The |setopts| function provides users with
% an interface to set options that control the algorithms used to implement
% these tasks. Default values are set automatically. In this example, we use
% the default options for |getevents| and |fitevents|.

%%
% Set the algorithm options.
opts.getevents = bfra.setopts('getevents');
opts.fitevents = bfra.setopts('fitevents');

%% 
% The following workflow consists of getting a list of recession events, fitting
% the recession events, and then estimating the recession constants _a_ and _b_
% using the point cloud method.

%% Step 1. Get events
EventData = bfra.getevents(T,Q,R,opts.getevents);

%% Step 2. Fit events
EventFits = bfra.fitevents(EventData,opts.fitevents);

%% Step 3. Fit recession parameters _a_ and _b_
% Pull out the event discharge and recession rate and pass them to the |fitab|
% function.
Q = EventFits.q;
dQdt = EventFits.dqdt;
abFit = bfra.fitab(Q,dQdt,'nls','plotfit',true);
snapnow
%%% Explore the fitted recession constants
% 
% The recession constants _a_ and _b_ are available in the |abFit| struct.
%  abFit.a = late-time recession constant in discharge equation -dQ/dt = aQ^b
%  abFit.b = late-time recession constant in discharge equation -dQ/dt = aQ^b
% 
% Print the fitted values to the screen using a latex-formatted character array.
%%
bfra.aQbString([abFit.a abFit.b],'printvalues',true)
a = abFit.ab(1);
b = abFit.ab(2);

