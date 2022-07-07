function [tau,q,dqdt,tags,t,L,s,dq] = bfra_eventtau(K,Events,Fits,varargin)

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p = MipInputParser;
   p.StructExpand = false;
   p.FunctionName = 'bfra_eventtau';
   p.addRequired('K',@(x)istable(x));
   p.addRequired('Events',@(x)isstruct(x));
   p.addRequired('Fits',@(x)isstruct(x));
   p.addParameter('usefits',false,@(x)islogical(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   dqfnc    = @(a,dqdt) -dqdt./a;   % must have derived this at some point
   Taufnc   = bfra_taufunc;
   Sfnc     = @(a,b,q) (q.^(2-b))./(a*(2-b));
   numfits  = height(K);            % use K b/c some 'Events' don't get fit
   
   Ktags    = K.eventTag;
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
   
   % i need to know which a/b value is associated with events for which
   % tau>taumin, which means I need 
   tags     = nan(size(Q));
   a        = nan(numfits,1);
   b        = nan(numfits,1);
   
   for m = 1:numfits
      tag      = Ktags(m);
      i        = Ktags == tag;   % should just be m
      ii       = Qtags == tag;   % Fits.eventTag == m;
      tau(ii)  = Taufnc(K.a(i),K.b(i),Q(ii));
      
% return fit q/dqdt for point cloud plot but use event q for tau
      iii       = Fits.eventTag == tag;
      q(iii)    = Fits.q(iii);
      dqdt(iii) = Fits.dqdt(iii);
      
      
      t(ii)    = 1:numel(Q(ii)); % should just be 1:sum(ii)
      s(ii)    = abs(tau(ii)./(2-K.b(i)).*Q(ii));
      dq(ii)   = dqfnc(K.a(i),dQdt(ii));
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
   
   
      
   
   