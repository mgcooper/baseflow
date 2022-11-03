function K = wrapFits( q,dqdt,deriv,method,order,station,eventdate,    ...
                        eventtag,fittag,fitcount,fitopts,K)
%BFRA.WRAPFITS estimates the recession coefficient (wrapper around bfra.fitab)
% 
%-------------------------------------------------------------------------------
%   Inputs:
%               q       = discharge timeseries
%               dqdt    = dQ/dt, t = time
%               deriv   = derivative method
%               method  = 'ols','mle','qtl','mean','median'
%               order   = power law exponent
%               station = char used to designate the discharge station
%               eventdate = datenum, datetime, or any other date
%               eventtag = scalar that numbers events from 1:numevents
%               fittag = scalar that numbers fits within events
%               fitcount = running count of all fits b/c we don't know ahead of
%                          time how many events will be fit but we need to
%                          index into the table K
%               fitopts = struct of fitting options to pass to fitab (not
%                          implemented)
%               K       = pre-allocated table for storing the output
%   
%   Outputs:    K = table of computed values including a,b,tau,S, and
%              confidence intervals
%-------------------------------------------------------------------------------

   warning off

% fit a/b
   [Fit,ok] = bfra.fitab(q,dqdt,method,'fitopts',fitopts);
   
% check for fitting failure
if ok == false
   K = setKnan(method,order,deriv,station,eventDate,eventTag,fitTag,K);
   return
end

% compute derived values
   a     =  Fit.a;
   b     =  Fit.b;
   q     =  Fit.x;

% this equation is valid for all values of b   
   tau   =  1/a*(median(q))^(1-b);   % recession timescale [T]
   tauL  =  1/a*(max(q))^(1-b);
   tauH  =  1/a*(min(q))^(1-b);

% event-scale storage range
   [Smin,Smax,dS] = bfra.dynamicS(a,b,min(q),max(q));


% package output
   K(fitcount).a           = Fit.a; 
   K(fitcount).b           = Fit.b;
   K(fitcount).tau         = tau;
   K(fitcount).aL          = Fit.aL;
   K(fitcount).bL          = Fit.bL;
   K(fitcount).tauL        = tauL;
   K(fitcount).aH          = Fit.aH;
   K(fitcount).bH          = Fit.bH;
   K(fitcount).tauH        = tauH;
   K(fitcount).rsq         = Fit.rsq;
   K(fitcount).pval        = Fit.pvalue;
   K(fitcount).N           = Fit.N;   
   K(fitcount).Smin        = Smin;
   K(fitcount).Smax        = Smax;
   K(fitcount).dS          = dS;
   K(fitcount).Qmin        = min(q);
   K(fitcount).Qmax        = max(q);
   K(fitcount).method      = method;
   K(fitcount).order       = order;
   K(fitcount).deriv       = deriv;
   K(fitcount).station     = station;
   K(fitcount).date        = eventdate;
   K(fitcount).eventTag    = eventtag;
   K(fitcount).fitTag      = fittag;

end

% if all the data is nan, set K nan
function K = setKnan(method,order,deriv,station,date,event,fit,K)
   K(idx).a         = nan;
   K(idx).b         = nan;
   K(idx).tau       = nan;
   K(idx).aL        = nan;
   K(idx).bL        = nan;
   K(idx).tauL      = nan;
   K(idx).aH        = nan;
   K(idx).bH        = nan;
   K(idx).tauH      = nan;
   K(idx).rsq       = nan;
   K(idx).pval      = nan;
   K(idx).N         = nan;
   K(idx).Smin      = nan;
   K(idx).Smax      = nan;
   K(idx).dS        = nan;
   K(idx).Qmin      = nan;
   K(idx).Qmax      = nan;
   K(idx).method    = method;
   K(idx).order     = order;
   K(idx).deriv     = deriv;
   K(idx).station   = station;
   K(idx).date      = date;
   K(idx).eventTag  = event;
   K(idx).fitTag    = fit;
end