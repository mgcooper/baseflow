function [K,Fits] = fitevents(Events,varargin)
%FITEVENTS wrapper around getdqdt and fitdqdt functions to fit all events
% 
% Inputs
% 
%     Events:  output of bfra.getevents (flow comes in as m3 d-1 posted daily)
% 
% Outputs
% 
%     K:       table of fitted values e.g., a, b, tau, for each event
%     Fits:    structure containing the fitted q/dqdt
% 
% See also: getdqdt, fitdqdt

%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'fitevents';

addRequired(p, 'Events',               @(x) isstruct(x)                 );
addParameter(p,'derivmethod', 'ETS',   @(x) ischar(x)                   );
addParameter(p,'fitmethod',   'nls',   @(x) ischar(x)                   );
addParameter(p,'fitorder',    'free',  @(x) ischar(x) | isnumeric(x)    );
addParameter(p,'fitnmin',     4,       @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'pickfits',    false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'pickmethod',  'none',  @(x) ischar(x)                   );
addParameter(p,'plotfits',    false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'savefitplots',false,   @(x) islogical(x) & isscalar(x)  );
addParameter(p,'etsparam',    0.2,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'vtsparam',    1,       @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'drainagearea',nan,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'gageID',      'none',  @(x) ischar(x)                   );

parse(p,Events,varargin{:});

opts     = p.Results;
fitopts  = struct(); % removed fitopts from parser, it may mess up autounpacking
%-------------------------------------------------------------------------------

% pull out the events
   A           =  opts.drainagearea;    % drainage area [m2]
   T           =  Events.t;                  % time [days]
   Q           =  Events.q;                  % daily discharge [m3 d-1] 
   R           =  Events.r;                  % daily rainfall [mm d-1]
   eventTags   =  Events.tag;
   numEvents   =  max(Events.tag);
   ax          =  'none';

   % initialize output structure and output arrays
   K              =  initK(10000);
   Fits.t         =  nan(size(Q));        % fitted t
   Fits.q         =  nan(size(Q));        % fitted Q
   Fits.r         =  nan(size(Q));        % rain
   Fits.dt        =  nan(size(Q));        % fitted dt
   Fits.dqdt      =  nan(size(Q));        % fitted dQdt
   Fits.eventTag  =  nan(size(Q));        % 1:numEvents
   Fits.fitTag    =  nan(size(Q));        % 1:numFits
   nFits          =  0;

%-------------------------------------------------------------------------------
% compute the recession constants
%-------------------------------------------------------------------------------
   
for thisEvent = 1:numEvents

   warning off
   
   eventIdx    = eventTags == thisEvent;
   eventT      = T(eventIdx);
   eventQ      = Q(eventIdx);
   eventR      = R(eventIdx);
   eventDate   = mean(eventT); % keep track of the event date

   if thisEvent == 1 && opts.plotfits == true
      macfig('monitor','mac','size','large'); ax = gca;
   end
   
   % get the q, dq/dt estimates (H=Hat)
   [qH,dH,dtH,tH]   = bfra.getdqdt( eventT,eventQ,eventR,               ...
                                    opts.derivmethod,                   ...
                                    'pickmethod',opts.pickmethod,       ...
                                    'fitmethod',opts.fitmethod,         ...
                                    'etsparam',opts.etsparam,           ...
                                    'plotfits',opts.plotfits,           ...
                                    'eventID',datestr(eventDate),       ...
                                    'ax',ax                             );

   if opts.plotfits == true
      fname = ['dqdt_' opts.gageID];
      pauseToSaveFig(eventT,fname,pausetosave,opts.savefitplots);
   end

   % if pickFits is true, then qHat,dHat, and tHat will be cell arrays
   numFits = numel(qH);
   
   for thisFit = 1:numFits

      [q,dqdt,dt,tq,nFits,tf] = prepFit(qH,dH,dtH,tH,thisFit,nFits);
      
      % if no flow was returned, continue
      if tf == true; continue; end
                        
      % otherwise fit the model (fit a/b)
         K  =  getFit(  q,dqdt,opts.derivmethod,opts.fitmethod,opts.fitorder, ...
                        opts.gageID,eventDate,thisEvent,thisFit, ...
                        nFits,fitopts,K);

      % post-process and save the fit
        [Fits,K,nFits] = saveFit(   K,Fits,nFits,thisFit,thisEvent,     ...
                                    T,A,q,dqdt,dt,tq);
   end
   
   % pause to look at the fits
   if opts.plotfits == true || opts.pickfits == true
%       %autoArrangeFigures(0,0,2,hEvents.f);
%       %autoArrangeFigures(0,0,2);
%       disp(['event fitting finished' newline]); % pause;
      clf; % close all
   end 

end

   % done with fitting, process outputs
   close all
   
% % commented this out for octave compatibility
%    % save the data for this gage and this derivative method
%    K = struct2table(K);
% 
%    if all(isnan(K.a))
%       K           =   [];
%    else
%       K.method    =   categorical(cellstr(K.method));
%       K.deriv     =   categorical(cellstr(K.deriv));
%       K.station   =   categorical(cellstr(K.station));
%    end   
   
%    % should convert Fits to timetable and add units
%    Fits.Time = Events.Time;
%    % variables are: t, q, r, dt, dqdt, eventTag, fitTag
%    units = ["days","m3 d-1","mm d-1","days","m3 d-2","-","-"];
%    Fits = struct2timetable(Fits,'VariableUnits',units);
   
end

%==========================================================================

function [q,dqdt,dt,tq,nFits,tf] = prepFit(qH,dH,dtH,tH,thisFit,nFits)
   
   % if there are multiple fits for an event, qHat, dHat, etc. will be cell
   % arrays. this pulls out the selected values to fit.
   
   if iscell(qH)
      q     = qH{thisFit};
      dqdt  = dH{thisFit};
      dt    = dtH{thisFit};
      tq    = datenum(tH{thisFit});
   else
      q     = qH;
      dqdt  = dH;
      dt    = dtH;
      tq    = datenum(tH);
   end

   % if no flow was returned, continue
   tf = false;
   if all(isnan(q))
      tf  = true;
   else
      nFits = nFits+1;
   end
   
end

%==========================================================================

function K = getFit(q,dqdt,derivmethod,fitmethod,fitorder,station,eventdate, ...
                     eventtag,fittag,fitcount,fitopts,K)


% Fit a/b
[Fit,ok] = bfra.fitab(q,dqdt,fitmethod,'fitopts',fitopts);

% check for fitting failure
if ok == false
   K = setfitnan(fitmethod,fitorder,derivmethod,station,eventdate,eventtag,...
         fittag,fitcount,K);
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
   [Smin,Smax,dS] = bfra.aquiferstorage(a,b,min(q),max(q));


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
   K(fitcount).method      = fitmethod;
   K(fitcount).order       = fitorder;
   K(fitcount).deriv       = derivmethod;
   K(fitcount).station     = station;
   K(fitcount).date        = eventdate;
   K(fitcount).eventTag    = eventtag;
   K(fitcount).fitTag      = fittag;
   
end
   
%==========================================================================

function [Fits,K,nFits] = saveFit(K,Fits,nFits,thisFit,thisEvent,      ...
                                   T,A,q,dqdt,dt,tq)

% if the fit failed, remove the entry and return to continue
   if isnan(K(nFits).a) % || K(nFits).b<=0
      K(nFits) = [];
      nFits    = nFits-1;
      return;
   end

   % scale storage by the basin area (convert S from m3->cm)
   if ~isnan(A)
      K(nFits).Smin  = K(nFits).Smin/A*100;
      K(nFits).Smax  = K(nFits).Smax/A*100;
      K(nFits).dS    = K(nFits).dS/A*100;
   end

   % collect all data for the point-cloud
   fitIdx                  =  ismember(T,tq);
   Fits.q(        fitIdx)  =  q;
   Fits.dqdt(     fitIdx)  =  dqdt;
   Fits.dt(       fitIdx)  =  dt;
   Fits.t(        fitIdx)  =  tq;
   Fits.eventTag( fitIdx)  =  thisEvent;
   Fits.fitTag(   fitIdx)  =  thisFit;

end

function pauseToSaveFig(T,fname,pausetosavefig,savefitplots)
   
   if pausetosavefig == true
   % optional: save the figure
      disp('press s to save the figure, p to pause code, or any other key to continue');
      ch = getkey();
      if ch==115
         fname = [fname '_' datenum2yyyyMMMdd(T) '.png'];
         exportgraphics(gcf,fname,'Resolution',300);
      elseif ch==112
         commandwindow
         pause;
      else
         commandwindow
      end
      
   elseif savefitplots == true
      fname = [fname '_' datenum2yyyyMMMdd(T) '.png'];
      exportgraphics(gcf,fname,'Resolution',300);
      commandwindow
   end

end

function K = setfitnan(method,order,deriv,station,date,event,fit,idx,K)
% SETFITNAN set all values of 'K' table nan except for algorithm settings
% 
%  Inputs
%  
%     method   =  fit method
%     order    =  model order
%     deriv    =  deriv method
%     station  =  station id
%     date     =  date of event
%     event    =  numeric tag to track events
%     fit      =  numeric tag to track fits
%     K        =  table of fits
% 
%  See also fitevents, getfits

% if all the data is nan, set K nan
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

function K = initK(N)

   K.a         = nan(N,1);
   K.b         = nan(N,1);
   K.tau       = nan(N,1);
   K.aL        = nan(N,1);
   K.bL        = nan(N,1);
   K.tauL      = nan(N,1);
   K.aH        = nan(N,1);
   K.bH        = nan(N,1);
   K.tauH      = nan(N,1);
   K.rsq       = nan(N,1);
   K.pval      = nan(N,1);
   K.N         = nan(N,1);
   K.Smin      = nan(N,1);
   K.Smax      = nan(N,1);
   K.dS        = nan(N,1);
   K.Qmin      = nan(N,1);
   K.Qmax      = nan(N,1);
   K.method    = nan(N,1);
   K.order     = nan(N,1);
   K.deriv     = nan(N,1);
   K.station   = nan(N,1);
   K.date      = nan(N,1);
   K.eventTag  = nan(N,1);
   K.fitTag    = nan(N,1);

end
