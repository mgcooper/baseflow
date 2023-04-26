function [t,q,r,Info] = findevents(T,Q,R,varargin)
%FINDEVENTS returns flow Q and time T values of each individual recession event,
%and info about the applied filters
%
% Required inputs:
%  T           =  time
%  Q           =  flow (m3/time)
%  R           =  rain (mm/time)
%
% Optional name-value inputs:
%  opts        =  (optional) structure containing the following fields:
%  qmin        =  minimum flow value, below which values are set nan
%  nmin        =  minimum event length
%  fmax        =  maximum # of missing values gap-filled
%  rmax        =  maximum run of sequential constant values
%  rmin        =  minimum rainfall required to censor flow (mm/day?)
%  cmax        =  maximum run of sequential convex dQ/dt values
%  rmconvex    =  remove convex derivatives
%  rmnochange  =  remove consecutive constant derivates
%  rmrain      =  remove rainfall
%  pickevents  =  option to manually pick events
%  plotevents  =  option to plot picked events
%
% Tip: events are identified by their indices on the t,q,r arrays, so if
% any filtering is applied prior to passing in the arrays, the data needs
% to be used in subsequent functions or the indices won't be correct
%
%  See also: getevents, eventsplitter, eventpicker, eventplotter

%-------------------------------------------------------------------------------
% input handling
%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'findevents';
p.CaseSensitive   = true;              % true because T,Q,R are sent back

addRequired(p, 'T',                  @(x) isnumeric(x) | isdatetime(x)     );
addRequired(p, 'Q',                  @(x) isnumeric(x) & numel(x)==numel(T));
addRequired(p, 'R',                  @(x) isnumeric(x)                     );
addParameter(p,'qmin',        0,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'nmin',        4,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'fmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'rmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'rmin',        0,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'cmax',        2,     @(x) isnumeric(x) & isscalar(x)       );
addParameter(p,'rmconvex',    false, @(x) islogical(x) & isscalar(x)       );
addParameter(p,'rmnochange',  false, @(x) islogical(x) & isscalar(x)       );
addParameter(p,'rmrain',      false, @(x) islogical(x) & isscalar(x)       );
addParameter(p,'pickevents',  false, @(x) islogical(x) & isscalar(x)       );
addParameter(p,'plotevents',  false, @(x) islogical(x) & isscalar(x)       );
addParameter(p,'asannual',    false, @(x) islogical(x) & isscalar(x)       );

parse(p,T,Q,R,varargin{:});

qmin        = p.Results.qmin;
nmin        = p.Results.nmin;
fmax        = p.Results.fmax;
rmax        = p.Results.rmax;
rmin        = p.Results.rmin;
cmax        = p.Results.cmax;
rmconvex    = p.Results.rmconvex;
rmnochange  = p.Results.rmnochange;
rmrain      = p.Results.rmrain;
pickevents  = p.Results.pickevents;
plotevents  = p.Results.plotevents;

%-------------------------------------------------------------------------------

% iF is the first non-nan index, to recover indices after removing nans
numdata     = numel(T);
Q(Q<qmin)   = nan;                              % set values < qmin nan
Q           = bfra.util.setconstantnan(Q,rmax); % set constant non-nan values nan
[T,Q,R,iF]  = bfra.util.rmleadingnans(T,Q,R);   % remove leading nans
[T,Q,R]     = bfra.util.rmtrailingnans(T,Q,R);  % remove trailing nans
Q           = bfra.util.fillnans(Q,fmax);       % gap fill missing values
Q           = bfra.util.smoothflow(Q);          % smooth measurement noise

% % for reference, two other options I tested
% [Q,win]   = smoothnoise(Q,'annual');  % smooth measurement noise
% [Q,win]   = smoothdata(Q,'sgolay');  % smooth measurement noise

if isempty(Q)||sum(~isnan(Q))<nmin % fast exit
   [t,q,r,Info] = bfra.util.setEventEmpty;
else

   % call eventfinder either way, then update if pickfits == true
   [t,q,r,Info] = bfra.eventfinder(T,Q,R, ...
      'nmin',        nmin,          ...
      'fmax',        fmax,          ...
      'rmax',        rmax,          ...
      'rmin',        rmin,          ...
      'rmconvex',    rmconvex,      ...
      'rmnochange',  rmnochange,    ...
      'rmrain',      rmrain         );

   Info = updateinfo(Info,iF,numdata);
   
   % for the window test
   % Info.winsize = win;
   
   % NOTE: eventpicker doesn't update Info for events that are picked
   % within an eventfinder event, but only Info.istart is used in the
   % main algorithm so it is sufficient at this point
   if pickevents == true
      [t,q,r,Info] = bfra.eventpicker(T,Q,R,nmin,Info);
   elseif plotevents == true
      Info.hEvents = bfra.eventplotter(T,Q,R,Info,'plotevents',plotevents);
   end
end

function Info = updateinfo(Info,ifirst,numdata)

fields = fieldnames(Info);

for m = 1:numel(fields)
   Info.(fields{m}) = Info.(fields{m}) + ifirst - 1;
end

Info.runlengths   = Info.istop - Info.istart + 1;
Info.ifirst       = ifirst;
Info.datalength   = numdata;