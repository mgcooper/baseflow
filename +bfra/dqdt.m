function [K,Fits] = dqdt(Events,varargin)
%BFRA.DQDT   
% Inputs:
%  Events: output of bfra.Events (flow comes in as m3 d-1 posted daily)
% Outputs:
%  K: table of fitted values e.g., a, b, tau, for each event
%  Fits: structure containing the fitted q/dqdt

%-------------------------------------------------------------------------------
p = MipInputParser;
p.FunctionName = 'bfra.dqdt';
p.addRequired( 'Events',               @(x) isstruct(x)                 );
p.addParameter('derivmethod', 'ETS',   @(x) ischar(x)                   );
p.addParameter('fitmethod',   'nls',   @(x) ischar(x)                   );
p.addParameter('fitorder',    'free',  @(x) ischar(x) | isnumeric(x)    );
p.addParameter('fitnmin',     4,       @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('pickfits',    false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('pickmethod',  'none',  @(x) ischar(x)                   );
p.addParameter('plotfits',    false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('savefitplots',false,   @(x) islogical(x) & isscalar(x)  );
p.addParameter('etsparam',    0.2,     @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('drainagearea',nan,     @(x) isnumeric(x) & isscalar(x)  );
p.addParameter('gageID',      'none',  @(x) ischar(x)                   );
p.addParameter('fitopts',     struct(),@(x) isstruct(x)                 );
p.parseMagically('caller');
% note: fitopts not implemented
%-------------------------------------------------------------------------------

% pull out the events
   A           =  drainagearea;           % drainage area [m2]
   T           =  Events.t;               % time [days]
   Q           =  Events.q;               % daily discharge [m3 d-1] 
   R           =  Events.r;               % daily rainfall [mm d-1]
   eventTags   =  Events.tag;
   numEvents   =  max(Events.tag);
   ax          =  'none';

   % initialize output structure and output arrays
   K              =  bfra.initK(10000);
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

   eventIdx    = eventTags == thisEvent;
   eventT      = T(eventIdx);
   eventQ      = Q(eventIdx);
   eventR      = R(eventIdx);
   eventDate   = mean(eventT); % keep track of the event date

   if thisEvent == 1 && plotfits == true
      macfig('monitor','mac','size','large'); ax = gca;
   end
   
   % get the q, dq/dt estimates (H=Hat)
   [qH,dH,dtH,tH]   = bfra.getdqdt( eventT,eventQ,eventR,derivmethod,   ...
                                    'pickmethod',pickmethod,            ...
                                    'fitmethod',fitmethod,              ...
                                    'etsparam',etsparam,                ...
                                    'plotfits',plotfits,                ...
                                    'eventID',datestr(eventDate),       ...
                                    'ax',ax                             );

   if plotfits == true
      fname = [opts.figs.dqdt 'dqdt_' gageID];
      pauseToSaveFig(eventT,fname,pausetosave,savefitplots);
   end

   % if pickFits is true, then qHat,dHat, and tHat will be cell arrays
   numFits = numel(qH);
   
   for thisFit = 1:numFits

      [q,dqdt,dt,tq,nFits,tf] = prepFit(qH,dH,dtH,tH,thisFit,nFits);
      
      % if no flow was returned, continue
      if tf == true; continue; end

      % otherwise fit the model
         K  =  bfra.Fit(  q,dqdt,derivmethod,fitmethod,fitorder, ...
                           gageID,eventDate,thisEvent,thisFit, ...
                           nFits,fitopts,K);

      % post-process and save the fit
        [Fits,K,nFits] = saveFits(  K,Fits,nFits,thisFit,thisEvent,     ...
                                    T,A,q,dqdt,dt,tq);
   end
   
   % pause to look at the fits
   if plotfits == true || pickfits == true
%       %autoArrangeFigures(0,0,2,hEvents.f);
%       %autoArrangeFigures(0,0,2);
%       disp(['event fitting finished' newline]); % pause;
      clf; % close all
   end 

end

   % done with fitting, process outputs
   close all
   
   % save the data for this gage and this derivative method
   K = struct2table(K);

   if all(isnan(K.a))
      K           =   [];
   else
      K.method    =   categorical(cellstr(K.method));
      K.deriv     =   categorical(cellstr(K.deriv));
      K.station   =   categorical(cellstr(K.station));
   end   
   
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

function [Fits,K,nFits] = saveFits(K,Fits,nFits,thisFit,thisEvent,      ...
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
      

function K = bfra.initK(N)

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
