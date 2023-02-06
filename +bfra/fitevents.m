function [K,Fits] = fitevents(Events,varargin)
%FITEVENTS wrapper around getdqdt and fitdqdt functions to fit all events
% 
% Syntax
% 
%     [K,Fits] = fitevents(Events,varargin)
% 
% Description
% 
%     [K,Fits] = fitevents(Events) fits all recession events in Events (output
%     of bfra.getevents) using default algorithm options.
% 
%     [K,Fits] = fitevents(Events,opts) uses user-supplied algorithm options in
%     struct opts. See bfra.setopts for automated option setting.
% 
% Required inputs
% 
%     Events   output of bfra.getevents (flow comes in as m3 d-1 posted daily)
% 
% Outputs
% 
%     K  table of fitted values e.g., a, b, tau, for each event
%     Fits  structure containing the fitted q/dqdt
% 
% See also getevents, getdqdt, fitdqdt
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'fitevents';
p.StructExpand    = true;
p.PartialMatching = true;

addRequired(p, 'Events',               @(x) isstruct(x)                 );
addParameter(p,'derivmethod', 'ETS',   @(x) ischar(x)                   );
addParameter(p,'fitmethod',   'nls',   @(x) ischar(x)                   );
addParameter(p,'fitorder',    'free',  @(x) ischar(x) | isnumeric(x)    );
addParameter(p,'pickfits',    false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'pickmethod',  'none',  @(x) ischar(x)                   );
addParameter(p,'plotfits',    false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'saveplots',   false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'etsparam',    0.2,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'vtsparam',    1.0,     @(x) isnumeric(x) & isscalar(x)  );


parse(p,Events,varargin{:});

derivmethod = p.Results.derivmethod;
fitmethod   = p.Results.fitmethod;
fitorder    = p.Results.fitorder;
pickfits    = p.Results.pickfits;
pickmethod  = p.Results.pickmethod;
plotfits    = p.Results.plotfits;
saveplots   = p.Results.saveplots;
etsparam    = p.Results.etsparam;
vtsparam    = p.Results.vtsparam;
fitopts     = struct(); % removed fitopts from parser, it may mess up autounpacking
%-------------------------------------------------------------------------------

% pull out the events
T           =  Events.t;               % time [days]
Q           =  Events.q;               % daily discharge [m3 d-1] 
R           =  Events.r;               % daily rainfall [mm d-1]
eventTags   =  Events.tag;
numEvents   =  max(Events.tag);
ax          =  'none';

% initialize output structure and output arrays
Fits.T         =  T;                   % NOTE: these are event-times, not T
Fits.Q         =  Q;                   % detected event-Q
Fits.t         =  NaT(size(Q));        % fitted t
Fits.q         =  nan(size(Q));        % fitted Q
Fits.r         =  nan(size(Q));        % rain
Fits.dt        =  nan(size(Q));        % fitted dt
Fits.dqdt      =  nan(size(Q));        % fitted dQdt
Fits.eventTag  =  nan(size(Q));        % 1:numEvents
Fits.fitTag    =  nan(size(Q));        % 1:numFits
nFits          =  0;

if pickmethod == "none"
   K = initFitTable(numEvents);
else
   K = initFitTable(numEvents*4); % allocate up to 4 picks/event 
end

savevars = {'a','b','aL','aH','bL','bH','rsq','pvalue','N'};

%-------------------------------------------------------------------------------
% compute the recession constants
%-------------------------------------------------------------------------------
warning off
debugflag = false;
   
for thisEvent = 1:numEvents

   eventIdx    = eventTags == thisEvent;
   eventT      = T(eventIdx);
   eventQ      = Q(eventIdx);
   eventR      = R(eventIdx);
   eventDate   = mean(eventT); % keep track of the event date

   if thisEvent == 1 && plotfits == true
      figure('Position',[1 1 658  576]); ax = gca;
   end
   
   % get the q, dq/dt estimates (H=Hat)
   
   [qH,dH,dtH,tH] = bfra.getdqdt(eventT,eventQ,eventR,derivmethod,   ...
      'pickmethod',pickmethod,'fitmethod',fitmethod,'etsparam',etsparam, ...
      'vtsparam',vtsparam,'plotfits',plotfits,'ax',ax,'flag',debugflag);
   
   if saveplots == true
      fname = ['dqdt_' datenum2yyyyMMMdd(eventT) '.png'];
      pauseSaveFig('s',fname);
   end

   % if pickFits is true, then qHat, dHat, and tHat will be cell arrays
   numFits = 1;
   if iscell(qH)
      numFits = numel(qH);
   end
   
   for thisFit = 1:numFits

      [q,dqdt,dt,tq,ok] = preparefit(qH,dH,dtH,tH,thisFit);
      
      % if no flow was returned, continue, otherwise fit a/b
      if ok == false
         continue
      else
         [Fit,ok] = bfra.fitab(q,dqdt,fitmethod,'fitopts',fitopts);
      end

      [Fits,K,nFits] = saveFit(T,q,dqdt,dt,tq,derivmethod,fitmethod,...
         fitorder,eventDate,thisEvent,thisFit,nFits,K,Fits,Fit,savevars,ok);
   end   
      
end

% remove fits that weren't kept
ikeep = ~isnan(K.a);
vars = fieldnames(K);
for n = 1:numel(vars)
   K.(vars{n}) = K.(vars{n})(ikeep);
end

%-------------------------------------------------------------------------------
% PREP FITS
%-------------------------------------------------------------------------------
function [q,dqdt,dt,tq,ok] = preparefit(q,dqdt,dt,tq,thisfit)
   
% if there are multiple fits for an event, qHat, dHat, etc. will be cell
% arrays. this pulls out the selected values to fit.

if iscell(q)
   q     = q{thisfit};
   dqdt  = dqdt{thisfit};
   dt    = dt{thisfit};
   tq    = tq{thisfit};
end

% if no flow was returned, continue
if all(isnan(q))
   ok = false;
else
   ok = true;
end

%-------------------------------------------------------------------------------
% GET FITS
%-------------------------------------------------------------------------------
function [Fits,K,fitcount] = saveFit(T,q,dqdt,dt,tq,derivmethod,fitmethod, ...
   fitorder,eventdate,eventtag,fittag,fitcount,K,Fits,Fit,savevars,ok)

% if fitting failed, set this event nan, otherwise save the fit
if ok == true

   fitcount = fitcount+1;
   
   for n = 1:numel(savevars)
      K.(savevars{n})(fitcount) = Fit.(savevars{n});
   end
   
   K.eventTag(fitcount)    = eventtag;
   K.fitTag(fitcount)      = fittag;
   
%    K.method(fitcount)      = fitmethod;
%    K.order(fitcount)       = fitorder;
%    K.deriv(fitcount)       = derivmethod;
%    K.station(fitcount)     = station;
%    K.date(fitcount)        = eventdate;
  

   % collect all data for the point-cloud
   fitIdx                  =  ismember(T,tq);
   Fits.q(        fitIdx)  =  q;
   Fits.dqdt(     fitIdx)  =  dqdt;
   Fits.dt(       fitIdx)  =  dt;
   Fits.t(        fitIdx)  =  tq;
   Fits.eventTag( fitIdx)  =  eventtag;
   Fits.fitTag(   fitIdx)  =  fittag;
   
   % at this point, with new ets retiming, we need to remove nan to have
   % eventTag and fitTag only span the rows with valid data, but as-is, we
   % should have eventTag equal to the raw data, and since the fitted data is
   % nan elsewhere, this might be better 

else
   
   % this shouldn't be necessary since they're initialized to nan
   
%    K.a(fitcount)         = nan;
%    K.b(fitcount)         = nan;
%    K.aL(fitcount)        = nan;
%    K.bL(fitcount)        = nan;
%    K.aH(fitcount)        = nan;
%    K.bH(fitcount)        = nan;
%    K.rsq(fitcount)       = nan;
%    K.pvalue(fitcount)    = nan;
%    K.N(fitcount)         = nan;
%    K.eventTag(fitcount)  = eventtag;
%    K.fitTag(fitcount)    = fittag;
   
   % K(idx).method    = method;
   % K(idx).order     = order;
   % K(idx).deriv     = deriv;
   % K(idx).station   = station;
   % K(idx).date      = date;

end


function K = initFitTable(N)

K.a         = nan(N,1);
K.b         = nan(N,1);
K.aL        = nan(N,1);
K.bL        = nan(N,1);
K.aH        = nan(N,1);
K.bH        = nan(N,1);
K.rsq       = nan(N,1);
K.pvalue    = nan(N,1);
K.N         = nan(N,1);
K.eventTag  = nan(N,1);
K.fitTag    = nan(N,1);

% these need to be redefined as strings or chars or soemthing other than nan
% K.method    = nan(N,1);
% K.order     = nan(N,1);
% K.deriv     = nan(N,1);
% K.station   = nan(N,1);
% K.date      = nan(N,1);



% % just here for reference

%          K = savefit(  Fit,q,dqdt,opts.derivmethod,opts.fitmethod,opts.fitorder, ...
%                         opts.gageID,eventDate,thisEvent,thisFit, ...
%                         nFits,fitopts,K);      

%       % post-process and save the fit
%         [Fits,K,nFits] = saveFit(   K,Fits,nFits,thisFit,thisEvent,     ...
%                                     T,A,q,dqdt,dt,tq);
