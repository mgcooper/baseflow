function [Events,Info] = getevents(T,Q,R,varargin)
%GETEVENTS get individual recession events from daily timeseries T, Q, and R.
%
% Syntax
%
%     Events = getevents(T,Q,R,varargin)
%
% Description
%
%     Events = getevents(T,Q,R) Detects, processes, and organizes individual
%     recession events from daily hydrograph timeseries T, Q, and rainfall R
%     using default algorithm options. Event discharge, timestamps, and
%     diagnostic info about the events are returned in output structure Events.
%     Note: this function is a wrapper around eventfinder to perform pre- and
%     post-processing and organize all recession events into the Events
%     structure.
%
%     Events = getevents(___,opts) uses user-defined options. See bfra.setopts
%     for default options and optional values.
%
%     [Events,Info] = getevents(___) also returns struct Info which contains the
%     indices of the identified local maxima, minima, convex points, candidate
%     recession values, kept recession values, and the start and stop index of
%     each kept event. Use this information with bfra.eventplotter.
%
%     Tip: events are identified by their indices on the t,q,r arrays, so if
%     any filtering is applied prior to passing in the arrays, the data needs
%     to be used in subsequent functions or the indices won't be correct
%
% Required inputs
%
%     T     time, nx1 vector of datetimes
%     Q     flow, nx1 vector of discharge (length/time) (assumed m3/day/day)
%     R     rain, nx1 vector of rainfall (length/time) (assumed mm/day)
%
% Optional name-value inputs
%
%     opts        (optional) structure containing the following fields:
%     qmin        minimum flow value, below which values are set nan
%     nmin        minimum event length
%     fmax        maximum # of missing values gap-filled
%     rmax        maximum run of sequential constant values
%     rmin        minimum rainfall required to censor flow (mm/day?)
%     cmax        maximum run of sequential convex dQ/dt values
%     rmconvex    remove convex derivatives
%     rmnochange  remove consecutive constant derivates
%     rmrain      remove rainfall
%     pickevents  option to manually pick events
%     plotevents  option to plot picked events
%
% See also fitevents, eventfinder, eventsplitter, eventpicker, eventplotter
%
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
% 
% Note to users: for data-heavy workflows, replace the Events output struct
% with the eventTags list. The Events struct includes the input data and the
% event-data for convenience, but the event-data can be easily extracted from
% the input data using the eventTags.

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% Updates
% 17 Jan: renamed old getevents to wrapevents and old findevents to getevents

%-------------------------------------------------------------------------------
% input handling
%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'getevents';
p.StructExpand    = true;
p.PartialMatching = false;
p.CaseSensitive   = true;              % true because T,Q,R are sent back

addRequired(p, 'T',                  @(x) isnumeric(x) | isdatetime(x)     );
addRequired(p, 'Q',                  @(x) isnumeric(x) & numel(x)==numel(T));
addRequired(p, 'R',                  @(x) isnumeric(x)                     );
addParameter(p,'qmin',        1,     @(x) isnumeric(x) & isscalar(x)       );
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
asannual    = p.Results.asannual;

%-------------------------------------------------------------------------------

% allow empyt R i.e. input syntax getevents(T,Q,[],...)
if isempty(R); R = zeros(size(Q)); end

% save the input data
Events.inputTime = T;
Events.inputFlow = Q;
Events.inputRain = R;

% iF is the first non-nan index, to recover indices after removing nans
numdata     = numel(T);
Q(Q<qmin)   = nan;                              % set values < qmin nan
Q           = bfra.util.setconstantnan(Q,rmax); % set constant non-nan values nan
[T,Q,R,iF]  = bfra.util.rmleadingnans(T,Q,R);   % remove leading nans
[T,Q,R]     = bfra.util.rmtrailingnans(T,Q,R);  % remove trailing nans
Q           = bfra.util.fillnans(Q,fmax);       % gap fill missing values

% smooth measurement noise
if asannual
   Q = bfra.util.smoothflow(Q);
end


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

   % NOTE: eventpicker doesn't update Info for events that are picked
   % within an eventfinder event, but only Info.istart is used in the
   % main algorithm so it is sufficient at this point
   if pickevents == true
      [t,q,r,Info] = bfra.eventpicker(T,Q,R,nmin,Info);
   elseif plotevents == true
      Info.hEvents = bfra.eventplotter(T,Q,R,Info,'plotevents',plotevents);
   end
end

% if asannual == false
   [ ...
      Events.eventTime, ...
      Events.eventFlow, ...
      Events.eventRain, ...
      Events.eventTags] = bfra.flattenevents(t,q,r,Info);
% end


function Info = updateinfo(Info,ifirst,numdata)

fields = fieldnames(Info);

for m = 1:numel(fields)
   Info.(fields{m}) = Info.(fields{m}) + ifirst - 1;
end

Info.runlengths   = Info.istop - Info.istart + 1;
Info.ifirst       = ifirst;
Info.datalength   = numdata;
