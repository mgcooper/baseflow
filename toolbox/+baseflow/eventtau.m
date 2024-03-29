function [tau,q,dqdt,tags,aggvals] = eventtau(Results,Events,Fits,varargin)
   %EVENTTAU Compute drainage timescale tau from event-scale parameters a and b.
   %
   % Syntax
   %
   %     [tau,q,dqdt,tags,aggvals] = eventtau(Results,Events,Fits)
   %
   % Description
   %
   %     tau = baseflow.eventtau(Results, Events, Fits) computes drainage timescale
   %     tau from event-scale parameters a,b, and flow Q using the structures K,
   %     Events, and Fits produced with baseflow.getevents and baseflow.fitevents
   %
   %     tau = baseflow.eventtau(_, 'aggfunc', aggfunc) aggregates the daily values
   %     to event-scale values using an aggregation function. Options are 'min',
   %     'max', 'mean', 'median'.
   %
   % See also: eventphi
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [Results, Events, Fits, usefits, aggfunc] = parseinputs( ...
      Results, Events, Fits, varargin{:});

   % MAIN FUNCTION
   Sfnc = baseflow.getfunction('SofabQ');
   dqfnc = @(a,dqdt) -dqdt./a; % must have derived this at some point
   taufnc = baseflow.getfunction('tauofabQ');

   if isscalar(Results)
      etags = Results.eventTag;
      a = Results.a;
      b = Results.b;
   else
      etags = [Results.eventTag];
      a = [Results.a];
      b = [Results.b];
   end

   numfits = numel(a); % use Results b/c some 'Events' don't get fit

   if usefits == true
      Q = Fits.q;
      dQdt = Fits.dqdt;
      Qtags = Fits.eventTags;
   else
      Q = Events.eventFlow;
      dQdt = Fits.dqdt;
      Qtags = Events.eventTags;
   end

   % Initialize values
   L = nan(numfits, 1);
   [q, t, s, dq, tau, dqdt] = deal(nan(size(Q)));

   % Initialize aggregated values
   [qagg, dqagg, tauagg] = deal(nan(numfits, 1));

   for m = 1:numfits
      tag = etags(m);
      i = etags == tag; % should just be m
      ii = Qtags == tag; % Fits.eventTags == m;
      tau(ii) = taufnc(a(i),b(i),Q(ii));

      % return fit q/dqdt for point cloud plot but use event q for tau
      iii = Fits.eventTags == tag;
      q(iii) = Fits.q(iii);
      dqdt(iii) = Fits.dqdt(iii);

      t(ii) = 1:numel(Q(ii)); % should just be 1:sum(ii)
      s(ii) = abs(tau(ii)./(2-b(i)).*Q(ii));
      dq(ii) = dqfnc(a(i),dQdt(ii));
      L(m) = sum(ii); % L is the length of each event

      % aggfunc
      switch aggfunc
         case 'none'
         case 'min'
            qagg(m) = nanmin(q(iii));
            dqagg(m) = nanmin(dqdt(iii));
            tauagg(m) = nanmin(tau(ii));
         case 'max'
            qagg(m) = nanmax(q(iii));
            dqagg(m) = nanmax(dqdt(iii));
            tauagg(m) = nanmax(tau(ii));
         case 'median'
            qagg(m) = nanmedian(q(iii));
            dqagg(m) = nanmedian(dqdt(iii));
            tauagg(m) = nanmedian(tau(ii));
         case 'mean'
            qagg(m) = nanmean(q(iii));
            dqagg(m) = nanmean(dqdt(iii));
            tauagg(m) = nanmean(tau(ii));
      end
   end

   inan = isnan(tau);

   q = q(~inan);
   s = s(~inan);
   t = t(~inan);
   dq = dq(~inan);
   tau = tau(~inan);
   dqdt = dqdt(~inan);
   tags = Qtags(~inan);

   aggvals.q = qagg;
   aggvals.dqdt = dqagg;
   aggvals.tau = tauagg;
end

%% INPUT PARSER
function [Results, Events, Fits, usefits, aggfunc] = parseinputs( ...
      Results, Events, Fits, varargin)

   parser = inputParser;
   parser.StructExpand = false;
   parser.FunctionName = 'baseflow.eventtau';

   parser.addRequired('Results', @isstruct);
   parser.addRequired('Events', @isstruct);
   parser.addRequired('Fits', @isstruct);
   parser.addParameter('usefits', false, @islogical);
   parser.addParameter('aggfunc', 'none', @ischar);

   parser.parse(Results, Events, Fits, varargin{:});

   Results = parser.Results.Results;
   Fits = parser.Results.Fits;
   Events = parser.Results.Events;
   usefits = parser.Results.usefits;
   aggfunc = parser.Results.aggfunc;
end
