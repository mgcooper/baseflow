function [x,y,logx,logy,weights,success] = prepfits(q,dqdt,varargin)
%BFRA.PREPFITS preps q and -dq/dt for event-scale fitting
% Required inputs:
%  q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%  dqdt        =  discharge rate of change (L T^-2)
% 
% Optional inputs:
%  weights  =  nx1 double of weights for the fitting algorithm
%  mask     =  nx1 logical mask to exclude values from fitting
% 
%  note: dqdt comes in as its actual value i.e. negative
% 
%  See also: fitab

%-------------------------------------------------------------------------------
   p = MipInputParser;
   p.addRequired('q',                           @(x)isnumeric(x)  );
   p.addRequired('dqdt',                        @(x)isnumeric(x)  );
   p.addParameter('weights',  ones(size(q)),    @(x)isnumeric(x)  );
   p.addParameter('mask',     true(size(q)),    @(x)islogical(x)  );
   p.parseMagically('caller');
   
   weights = p.Results.weights;
   mask = p.Results.mask;
%-------------------------------------------------------------------------------

   % take the negative dq/dt values
   ok       = dqdt<0;
   x        = abs(q(ok));
   y        = abs(dqdt(ok));
   weights  = weights(ok);
   mask     = mask(ok);
   
   % convert the mask to weights
   weights(mask==false) = 0;
   
   logx  = log(x);
   logy  = log(y);
   
   [  x,    ...
      y,    ...
      weights ]   = prepareCurveData( x, y, weights );
     
     
   [  logx, ...
      logy, ...
      weights ]   = prepareCurveData(logx,logy,weights);
   

   success = true;
   if numel(y)<4 % || numnodif >4
      success = false;
   end
   
end
