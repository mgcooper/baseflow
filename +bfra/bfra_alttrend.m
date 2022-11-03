function [D,dDdt,dDadt,C] = bfra_alttrend(tau,phi,N,Qb,dQbdt)
%BFRA_ALTTREND computes the linear trend in active layer (aquifer) thickness
% Inputs:
%  tau = drainage timescale, scalar [time in days]
%  phi = drainable porosity, scalar [volume/volume]
%  N = 3-2*b, b = exponent in -dQ/dt = aQ^b, scalar [unitless]
%  Qb = baseflow timeseries, posted annually [cm/day] (could be any
%  length scale unit per day)
%  dQbdt (optional) = baseflow rate of change timeseries [cm/day/year] (could
%  be any length scale per day per any timescale)
   
   % compute the sensitivity coefficient from the fitted values
   C = tau/phi/(N+1); % lambda in the paper [days]

   % compute the timeseries of ALT and the trend
   D        = Qb.*C;              % alt timeseries, posted annually [cm]
   dDdt     = dQbdt.*C;           % alt trend, posted annually [cm/yr]
   dDadt    = anomaly(dQbdt.*C);  % alt trend anomaly(dDdt)
   
end