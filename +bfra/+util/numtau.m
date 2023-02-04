function N = numtau(Fits)

% this can accept Fits or Events or GlobalFit but eventually 
if isfield(Fits,'tag')
   N = numel(Fits.tag(~isnan(Fits.tag)));
elseif isfield(Fits,'eventTag')
   N = numel(Fits.eventTag(~isnan(Fits.eventTag)));
elseif inputname(1) == "GlobalFit"
   N = numel(Fits.x);
end