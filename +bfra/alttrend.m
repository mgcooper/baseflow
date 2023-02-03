function [D,dDdt,dDadt,C] = alttrend(tau,phi,N,Qb,dQbdt)
%ALTTREND compute the linear trend in active layer (aquifer) thickness
% 
% Syntax
% 
%     [D,dDdt,dDadt,C] = alttrend(tau,phi,N,Qb,dQbdt)
% 
% Description
% 
%     [D,dDdt,dDadt,C] = alttrend(tau,phi,N,Qb,dQbdt) computes the linear trend
%     in saturated aquifer thickness using aquifer properties and the linear
%     trend in streamflow. Tau, phi, and N are aquifer properties identified as
%     baseflow recession parameters and Qb is baseflow. Output D is the
%     interannual value of saturated aquifer thickness, dDdt is the trendline,
%     dDadt is the trendline fitted to anomalies, and C is the sensitivity
%     coefficient.
% 
% Required inputs
% 
%     tau = drainage timescale, scalar [time in days]
%     phi = drainable porosity, scalar [volume/volume]
%     N = 3-2*b, b = exponent in -dQ/dt = aQ^b, scalar [unitless]
%     Qb = baseflow timeseries, posted annually [cm/day] (could be any
%     length scale unit per day)
%     dQbdt (optional) = baseflow rate of change timeseries [cm/day/year] (could
%     be any length scale per day per any timescale)
% 
% See also baseflowtrend, aquiferthickness
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% compute the sensitivity coefficient from the fitted values
C = tau/phi/(N+1); % lambda in the paper [days]

% compute the timeseries of ALT and the trend
D        = Qb.*C;              % alt timeseries, posted annually [cm]
dDdt     = dQbdt.*C;           % alt trend, posted annually [cm/yr]
dDadt    = anomaly(dQbdt.*C);  % alt trend anomaly(dDdt)
