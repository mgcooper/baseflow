
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