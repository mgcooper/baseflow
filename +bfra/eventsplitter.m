function [T,Q,R,Info] = eventsplitter(t,q,r,varargin)
%eventsplitter splits events into useable segments eg if an event is
%interrupted by rainfall or convex dq/dt, the event is split into separate
%segments.
% 
% Required inputs:
%  t           =  time
%  q           =  flow (m3/time)
%  r           =  rain (mm/time)
%
% Optional name-value inputs:
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmin        =  minimum rainfall required to censor flow (mm/day?)
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
% 
%  See also: getevents, eventfinder, eventpicker, eventplotter

% parse inputs
%-------------------------------------------------------------------------------
p = MipInputParser();
p.FunctionName = 'eventsplitter';
p.addRequired( 't',                  @(x) isnumeric(x) | isdatetime(x)  );
p.addRequired( 'q',                  @(x) isnumeric(x) & numel(x)==numel(t) );
p.addRequired( 'r',                  @(x) isnumeric(x)                  );
p.addParameter('nmin',        4,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('fmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmin',        0,     @(x) isnumeric(x) & isscalar(x)    );
p.addParameter('rmconvex',    false, @(x) islogical(x) & isscalar(x)    );
p.addParameter('rmnochange',  false, @(x) islogical(x) & isscalar(x)    );
p.addParameter('rmrain',      false, @(x) islogical(x) & isscalar(x)    );
p.parseMagically('caller');
%-------------------------------------------------------------------------------
% % other way to parse inputs:
%    arguments
%       t           datetime                         = 1
%       q           double                           = 2
%       r           double                           = 3
%       opts.nmin   double {mustBePositive}          = 4
%       opts.rmin   double {mustBePositive}          = 5
%       opts.rmax   double {mustBePositive}          = 6
%    end    
%-------------------------------------------------------------------------------

% below follows recommendations in Dralle et al. 2017

% get a 3-day smoothed timeseries to control false positive convexity
   qsmooth = smoothdata(q,'movmean',3);

% Part 1: find data to be excluded (run the filters)
    
   % filters: +dq/dt, peaks +1 day, convex +1 day, and mins -1 day
   ipos    = find([0;diff(q)]>0);
   imax    = find(islocalmax(q));
   imin    = find(islocalmin(q));
   icon    = find(islocalmax([0;diff(q)])&islocalmax([0;diff(qsmooth)]))+1;
% Dralle: keep if dq/dt<0 AND d2q/dt2>0 (concave up) in BOTH the raw and
% smoothed data, i.e. exclude if both raw AND smoothed data are convex
   dqdt1   = [0;diff(q)];
   dqdt2   = [0;diff(qsmooth)];
   d2qdt1  = [0;diff(dqdt1)];
   d2qdt2  = [0;diff(dqdt2)];
   icon2   = find(d2qdt1<=0 & d2qdt2<=0)-1; icon2 = icon2(icon2>0);
   
   % icon always occurs on peaks and one day prior, remove them from icon,
   % the peak will remain in imax, and one day prior in ipos
   icon    = icon(~ismember((icon),imax));
   
   % if the first (last) point is a local max (min), add them here
   if q(2)<q(1);       imax = [1; imax];           end
   if q(end)<q(end-1); imin = [imin;length(q)];    end

% Part 2: exclude the data (apply the filters)
   ibad = [ipos;imax;imax+1;imin];
   
   % remove the convex points if requested
   if rmconvex == true
      ibad  = [ibad;icon];
   end
    
   % exclude sequences of two or more of (dq/dt = 0) (see setconstantnan)
   if rmnochange == true
      inoc  = [0;diff([0;diff(q)])]; inoc(inoc~=0) = nan;
      inoc  = find(isminlength(inoc,rmax));
      ibad  = [ibad;inoc];
   end
   
   % exclude days with rain > rmin and convex recession 
   % also exclude 3 days before/after and combine with ibad 
   if rmrain == true   
      irain = find(r>rmin);
      irain = unique([irain;irain+1;irain-1;irain+2;irain-2;irain+3;irain-3]);
      irain = irain(ismember(irain,icon2));
      ibad  = [ibad;irain];
      
   end
   
   % take the unique indices and exclude 0 and >numel(q)
   ibad                 = unique(ibad);
   ibad(ibad<=0)        = [];
   ibad(ibad>numel(q))  = [];
    
% Part 3: extract each valid recession event    
    
    % proceed from here
    tfc         = true(size(q));            % initialize candidates true
    tfk         = ones(size(q));            % initialize run lengths
    tfc(ibad)   = false;                    % set unuseable values false
    tfk(ibad)   = nan;                      % set unuseable values nan
    [tfk,is,ie] = isminlength(tfk,nmin);    % find events >= min length
    rl          = ie-is+1;                  % event (run) lengths
    
    % pull out the events
    Nevents     = numel(is);
    T           = cell(Nevents,1);
    Q           = cell(Nevents,1);
    R           = cell(Nevents,1);
    
    % apply min length filter and keep remaining events
    for n = 1:Nevents   
        
        % if event length < min length, ignore it
        if rl(n)<nmin
            Nevents = Nevents-1; 
            continue; 
        end 
        qi  = q(is(n):ie(n)); 
        if islineconvex(qi) || islinepositive(qi)
            Nevents=Nevents-1;
            continue; 
        end
        
        T{n} = t(is(n):ie(n));
        Q{n} = q(is(n):ie(n));
        R{n} = r(is(n):ie(n));
        
    end

    % return events that passed the nmin filter
    if Nevents > 0
        Info.imaxima    = imax;
        Info.iminima    = imin;
        Info.iconvex    = icon;
        Info.icandidate = find(tfc);
        Info.ikeep      = find(tfk);
        Info.istart     = is;
        Info.istop      = ie;
    else
        [T,Q,R,Info]    = seteventnan;
    end
    
end