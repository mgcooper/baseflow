function [D,dDdt,dDadt,C] = bfra_alttrend(tau,phi,N,Qb,dQbdt)
   
   % compute the sensitivity coefficient from the fitted values
   C        = tau/phi/(N+1);

   % compute the timeseries of ALT and the trend
   D        = Qb.*C;              % alt timeseries (was Data.Qavg.*C./f)
   dDdt     = dQbdt.*C;           % alt trend
   dDadt    = anomaly(dQbdt.*C);  % = anomaly(dDdt)

   
end