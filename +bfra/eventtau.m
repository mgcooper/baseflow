function [tau,q,dqdt,tags,t,L,s,dq] = eventtau(K,Events,Fits,varargin)
%EVENTTAU computes drainage timescale tau from the event-scale parameters
%a,b, and flow Q using the structures K, Events, and Fits produced with
%bfra.getevents and bfra.dqdt 

%-------------------------------------------------------------------------------
p = inputParser;
p.StructExpand = false;
p.FunctionName = 'eventtau';
addRequired(p,'K',@(x)isstruct(x));
addRequired(p,'Events',@(x)isstruct(x));
addRequired(p,'Fits',@(x)isstruct(x));
addParameter(p,'usefits',false,@(x)islogical(x));
addParameter(p,'aggfunc','none',@(x)ischar(x));
parse(p,K,Events,Fits,varargin{:});
usefits = p.Results.usefits;
aggfunc = p.Results.aggfunc;
%-------------------------------------------------------------------------------

% TODO: implement aggfunc option to compute an event-aggregate tau e.g. using
% the mean flow, median flow, max flow, or min flow

   dqfnc    = @(a,dqdt) -dqdt./a;   % must have derived this at some point
   Taufnc   = bfra.taufunc;
   Sfnc     = @(a,b,q) (q.^(2-b))./(a*(2-b));
   numfits  = numel(K);            % use K b/c some 'Events' don't get fit
   
   Ktags    = [K.eventTag];
   a        = [K.a];
   b        = [K.b];
   
   if usefits == true
      Q     = Fits.q;
      dQdt  = Fits.dqdt;
      Qtags = Fits.eventTag;
   else
      Q     = Events.q;
      dQdt  = Fits.dqdt;
      Qtags = Events.tag;
      
   end
   
   tau      = nan(size(Q));
   q        = nan(size(Q));
   dqdt     = nan(size(Q));
   t        = nan(size(Q));
   s        = nan(size(Q));
   dq       = nan(size(Q));
   L        = nan(numfits,1);
   
   for m = 1:numfits
      tag      = Ktags(m);
      i        = Ktags == tag;   % should just be m
      ii       = Qtags == tag;   % Fits.eventTag == m;
      tau(ii)  = Taufnc(a(i),b(i),Q(ii));
      
% return fit q/dqdt for point cloud plot but use event q for tau
      iii       = Fits.eventTag == tag;
      q(iii)    = Fits.q(iii);
      dqdt(iii) = Fits.dqdt(iii);
      
      
      t(ii)    = 1:numel(Q(ii)); % should just be 1:sum(ii)
      s(ii)    = abs(tau(ii)./(2-b(i)).*Q(ii));
      dq(ii)   = dqfnc(a(i),dQdt(ii));
      L(m)     = sum(ii); % L is the length of each event
      
   end
   
   inan     = isnan(tau);
   tau      = tau(~inan);
   q        = q(~inan);
   dqdt     = dqdt(~inan);
   s        = s(~inan);
   t        = t(~inan);
   dq       = dq(~inan);
   
   tags     = Events.tag(~inan);
   
   
      
   
   