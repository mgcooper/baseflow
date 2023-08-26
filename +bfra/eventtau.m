function [tau,q,dqdt,tags,aggvals] = eventtau(K,Events,Fits,varargin)
%EVENTTAU compute drainage timescale tau from event-scale parameters a and b 
% 
% Syntax
% 
%     [tau,q,dqdt,tags,aggvals] = eventtau(K,Events,Fits,varargin)
% 
% Description
% 
%     tau = bfra.eventtau(K,Events,Fits) computes drainage timescale tau from
%     event-scale parameters a,b, and flow Q using the structures K, Events, 
%     and Fits produced with bfra.getevents and bfra.fitevents
% 
%     tau = bfra.eventtau(___,'aggfunc',aggfunc) aggregates the daily values
%     to event-scale values using an aggregation function. Options are 'min',
%     'max', 'mean', 'median'.
% 
% See also eventphi
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% TODO: implement aggfunc option to compute an event-aggregate tau e.g. using
% the mean flow, median flow, max flow, or min flow

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% PARSE INPUTS
[K, Events, Fits, usefits, aggfunc] = parseinputs(K, Events, Fits, varargin{:});

% MAIN FUNCTION
Sfnc = bfra.getfunction('SofabQ');
dqfnc = @(a,dqdt) -dqdt./a; % must have derived this at some point
taufnc = bfra.getfunction('tauofabQ');

if isscalar(K)
   Ktags = K.eventTag;
   a = K.a;
   b = K.b;
else
   Ktags = [K.eventTag];
   a = [K.a];
   b = [K.b];
end

numfits = numel(a);  % use K b/c some 'Events' don't get fit

if usefits == true
   Q = Fits.q;
   dQdt = Fits.dqdt;
   Qtags = Fits.eventTags;
else
   Q = Events.eventFlow;
   dQdt= Fits.dqdt;
   Qtags = Events.eventTags;

end

tau      = nan(size(Q));
q        = nan(size(Q));
dqdt     = nan(size(Q));
t        = nan(size(Q));
s        = nan(size(Q));
dq       = nan(size(Q));
L        = nan(numfits,1);

% 
qagg     = nan(numfits,1);
dqagg    = nan(numfits,1);
tauagg   = nan(numfits,1);

for m = 1:numfits
   tag      = Ktags(m);
   i        = Ktags == tag;   % should just be m
   ii       = Qtags == tag;   % Fits.eventTags == m;
   tau(ii)  = taufnc(a(i),b(i),Q(ii));

% return fit q/dqdt for point cloud plot but use event q for tau
   iii       = Fits.eventTags == tag;
   q(iii)    = Fits.q(iii);
   dqdt(iii) = Fits.dqdt(iii);


   t(ii)    = 1:numel(Q(ii)); % should just be 1:sum(ii)
   s(ii)    = abs(tau(ii)./(2-b(i)).*Q(ii));
   dq(ii)   = dqfnc(a(i),dQdt(ii));
   L(m)     = sum(ii); % L is the length of each event

   % aggfunc 
   switch aggfunc
      case 'none'
      case 'min'
         qagg(m)  = min(q(iii),[],'omitnan');
         dqagg(m) = min(dqdt(iii),[],'omitnan');
         tauagg(m) = min(tau(ii),[],'omitnan');
      case 'max'
         qagg(m)  = max(q(iii),[],'omitnan');
         dqagg(m) = max(dqdt(iii),[],'omitnan');
         tauagg(m) = max(tau(ii),[],'omitnan');
      case 'median'
         qagg(m)  = median(q(iii),'omitnan');
         dqagg(m) = median(dqdt(iii),'omitnan');
         tauagg(m) = median(tau(ii),'omitnan');
      case 'mean'
         qagg(m)  = mean(q(iii),'omitnan');
         dqagg(m) = mean(dqdt(iii),'omitnan');
         tauagg(m) = mean(tau(ii),'omitnan');
   end
   
end

inan     = isnan(tau);
tau      = tau(~inan);
q        = q(~inan);
dqdt     = dqdt(~inan);
s        = s(~inan);
t        = t(~inan);
dq       = dq(~inan);
tags     = Qtags(~inan);

aggvals.q = qagg;
aggvals.dqdt = dqagg;
aggvals.tau = tauagg;

%% INPUT PARSER
function [K, Events, Fits, usefits, aggfunc] = parseinputs(K, Events, Fits, varargin)

parser = inputParser;
parser.StructExpand = false;
parser.FunctionName = 'bfra.eventtau';

parser.addRequired('K', @isstruct);
parser.addRequired('Events', @isstruct);
parser.addRequired('Fits', @isstruct);
parser.addParameter('usefits', false, @islogical);
parser.addParameter('aggfunc', 'none', @ischar);

parser.parse(K, Events, Fits, varargin{:});

K = parser.Results.K;
Fits = parser.Results.Fits;
Events = parser.Results.Events;
usefits = parser.Results.usefits;
aggfunc = parser.Results.aggfunc;
