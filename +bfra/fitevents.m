function [Fits,Results] = fitevents(Events,varargin)
%FITEVENTS wrapper around getdqdt and fitdqdt functions to fit all events
% 
% Syntax
% 
%     [Fits,Results] = fitevents(Events,varargin)
% 
% Description
% 
%     [Fits,Results] = fitevents(Events) fits all recession events in Events
%     (output of bfra.getevents) using default algorithm options.
% 
%     [Fits,Results] = fitevents(Events,opts) uses user-supplied
%     algorithm options in struct opts. See bfra.setopts to set options.
% 
% Required inputs
% 
%     Events: output of bfra.getevents (flow comes in as m3 d-1 posted daily)
% 
% Outputs
% 
%     Fits: structure containing the fitted q/dqdt data
%     Results: table of fitted values e.g., a, b, tau, for each event
% 
% See also getevents, getdqdt, fitdqdt
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
% 
% TODO: move subfunctions to private/ to manage warnings, input parsing, and
% special-case fitting routines including octave compatibility once, here. This
% will be most problematic for fitab, because it is useful as a standalone
% function for fitting a single event. 

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = 'fitevents';
p.StructExpand = true;
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
T           =  Events.eventTime;       % time [days]
Q           =  Events.eventFlow;       % daily discharge [m3 d-1] 
R           =  Events.eventRain;       % daily rainfall [mm d-1]
eventTags   =  Events.eventTags;
numEvents   =  max(eventTags);
ax          =  'none';

% initialize output structure and output arrays
Fits.eventTime =  Events.eventTime;    % event-times
Fits.eventFlow =  Events.eventFlow;    % detected event-Q
Fits.t         =  NaT(size(Q));        % fitted t
Fits.q         =  nan(size(Q));        % fitted Q
Fits.r         =  nan(size(Q));        % rain
Fits.dt        =  nan(size(Q));        % fitted dt
Fits.dqdt      =  nan(size(Q));        % fitted dQdt
Fits.eventTags =  nan(size(Q));        % 1:numEvents
Fits.fitTags   =  nan(size(Q));        % 1:numFits
nFits          =  0;

if pickmethod == "none"
   Results = initFitTable(numEvents);
else
   Results = initFitTable(numEvents*4); % allocate up to 4 picks/event 
end

savevars = {'a','b','aL','aH','bL','bH','rsq','pvalue','N'};

%-------------------------------------------------------------------------------
% compute the recession constants
%-------------------------------------------------------------------------------

% A note on warnings. Nonlinear curve fitting to recession sequences generates a
% few characteristic errors. One is when dQ/dt increases as Q decreases. This
% could be interpreted to mean the recession sequence is not actually a
% recession, but this interpretation is not applied here. This case tends to
% produce a rank-deficient error from the left division of the jacobian (warning
% rankDeficientMatrix), or an error that indicates some elements of the jacobian
% are effectively zero at the solution (warning ModelConstantWRTParam), meaning
% the model is insensitive to one or more parameters. Another case is when the Q
% vs -dQ/dt relationship is convex, which the functional form does not
% accomodate. This tends to produce an ill-conditioned Jacobian (warning
% IllConditionedJacobian), which makes sense, it means the parameters cannot be
% identified. Both cases above can also lead to an iteration limit exceeded
% error (warning IterationLimitExceeded).
if bfra.util.isoctave == true
else
   warning('off','MATLAB:rankDeficientMatrix');
   warning('off','stats:nlinfit:IterationLimitExceeded');
   warning('off','stats:nlinfit:ModelConstantWRTParam');
   warning('off','stats:nlinfit:IllConditionedJacobian');
   warning('off','bfra:deps:rsquare:NegativeRsquared');
end

debugflag = false;
   
for thisEvent = 1:numEvents

   eventIdx    = eventTags == thisEvent;
   eventT      = T(eventIdx);
   eventQ      = Q(eventIdx);
   eventR      = R(eventIdx);
   eventDate   = mean(eventT); % keep track of the event date

   % if this is activated, need method to plot in getdqdt
   % if thisEvent == 1 && plotfits == true
   %    figure('Position',[1 1 658  576]); ax = gca;
   % end
   
   % get the q, dq/dt estimates (H=Hat)
   
   [qH,dH,dtH,tH] = bfra.getdqdt(eventT,eventQ,eventR,derivmethod,   ...
      'pickmethod',pickmethod,'fitmethod',fitmethod,'etsparam',etsparam, ...
      'vtsparam',vtsparam);
   
   % undocumented feature
   if saveplots == true
      % yyyyMMMdd = sprintf('%d_%d_%d',year(eventT),month(eventT),day(eventT));
      % fname = ['dqdt_' yyyyMMMdd '.png'];
      % pauseSaveFig('s',fname);
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
         [iFit,ok] = bfra.fitab(q,dqdt,fitmethod,'fitopts',fitopts);
      end

      [Fits,Results,nFits] = saveFit(T,q,dqdt,dt,tq,derivmethod,fitmethod,...
         fitorder,eventDate,thisEvent,thisFit,nFits,Results,Fits,iFit,savevars,ok);
   end   
      
end

% remove fits that weren't kept
ikeep = ~isnan(Results.a);
vars = fieldnames(Results);
for n = 1:numel(vars)
   Results.(vars{n}) = Results.(vars{n})(ikeep);
end


% TURN WARNINGS BACK ON
if bfra.util.isoctave == true
else
   warning('on','MATLAB:rankDeficientMatrix');
   warning('on','stats:nlinfit:IterationLimitExceeded');
   warning('on','stats:nlinfit:ModelConstantWRTParam');
   warning('on','stats:nlinfit:IllConditionedJacobian');
   warning('on','bfra:deps:rsquare:NegativeRsquared');
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
   fitorder,eventdate,eventtag,fittag,fitcount,K,Fits,iFit,savevars,ok)

% if fitting failed, set this event nan, otherwise save the fit
if ok == true

   fitcount = fitcount+1;
   
   for n = 1:numel(savevars)
      K.(savevars{n})(fitcount) = iFit.(savevars{n});
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
   %fitIdx                  =  ismember(T,datenum(tq)); % TEST
   Fits.q(        fitIdx)  =  q;
   Fits.dqdt(     fitIdx)  =  dqdt;
   Fits.dt(       fitIdx)  =  dt;
   Fits.t(        fitIdx)  =  tq;
   Fits.eventTags(fitIdx)  =  eventtag;
   Fits.fitTags(  fitIdx)  =  fittag;
   
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
