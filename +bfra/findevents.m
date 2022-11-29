function [T,Q,R,Info] = findevents(t,q,r,varargin)
%FINDEVENTS returns flow Q and time T values of each individual recession event,
%and info about the applied filters 
% 
% Required inputs:
%  t           =  time
%  q           =  flow (m3/time)
%  r           =  rain (mm/time)
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

addRequired(p, 't',                  @(x) isnumeric(x) | isdatetime(x)  );
addRequired(p, 'q',                  @(x) isnumeric(x) & numel(x)==numel(t) );
addRequired(p, 'r',                  @(x) isnumeric(x)                  );
addParameter(p,'qmin',        0,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'nmin',        4,     @(x) isnumeric(x) & isscalar(x)    );
addParameter(p,'fmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
addParameter(p,'rmax',        2,     @(x) isnumeric(x) & isscalar(x)    );
addParameter(p,'rmin',        0,     @(x) isnumeric(x) & isscalar(x)    );
addParameter(p,'cmax',        2,     @(x) isnumeric(x) & isscalar(x)  );
addParameter(p,'rmconvex',    false, @(x) islogical(x) & isscalar(x)    );
addParameter(p,'rmnochange',  false, @(x) islogical(x) & isscalar(x)    );
addParameter(p,'rmrain',      false, @(x) islogical(x) & isscalar(x)    );
addParameter(p,'pickevents',  false, @(x) islogical(x) & isscalar(x)  );
addParameter(p,'plotevents',  false, @(x) islogical(x) & isscalar(x)  );

parse(p,t,q,r,varargin{:});

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
numdata     = numel(t);
q(q<qmin)   = nan;                      % set values < qmin nan
q           = setconstantnan(q,rmax);   % set constant non-nan values nan
[t,q,r,iF]  = rmleadingnans(t,q,r);     % remove leading nans 
[t,q,r]     = rmtrailingnans(t,q,r);    % remove trailing nans
q           = fillnans(q,fmax);         % gap fill missing values
q           = smoothflow(q);            % apply a smoothing filter

if isempty(q)||sum(~isnan(q))<nmin     % fast exit
   
   [T,Q,R,Info] = bfra.seteventnan;   % note this returns [] not nan
   
else
   % call eventfinder either way, then update if pickfits == true
   [T,Q,R,Info] = bfra.eventfinder(t,q,r,                          ...
                                    'nmin',        nmin,          ...
                                    'fmax',        fmax,          ...
                                    'rmax',        rmax,          ...
                                    'rmin',        rmin,          ...
                                    'rmconvex',    rmconvex,      ...
                                    'rmnochange',  rmnochange,    ...
                                    'rmrain',      rmrain         );

   Info = updateinfo(Info,iF,numdata);

   % NOTE: eventpicker doesn't update Info for events that are picked
   % within an eventfinder event, but only Info.istart is used in the
   % main algorithm so it is sufficient at this point
   if pickevents == true
      [T,Q,R,Info] = bfra.eventpicker(t,q,r,nmin,Info);
   elseif plotevents == true
      Info.hEvents = bfra.eventplotter(t,q,r,Info,'plotevents',plotevents);
   end
end

% This effectively eliminates the need for bfra.getevents, but requires
% modifying the output of this function and dealing with the modifications to
% inputs t,q,r, meaning Events.t, q,r would be added at the start not here. for
% now, I am doing this outside of this function.
% Events = bfra.flattenevents(T,Q,R,t,q,r,Info);


function Info = updateinfo(Info,ifirst,numdata)

   fields = fieldnames(Info);
   
   for m = 1:numel(fields)
      Info.(fields{m}) = Info.(fields{m}) + ifirst - 1;
   end
   
   Info.runlengths   = Info.istop - Info.istart + 1;
   Info.ifirst       = ifirst;
   Info.datalength   = numdata;
   