function [Events, Info] = wrapevents(T,Q,R,varargin)
   %ANNUALEVENTS Detect recession events on an annual calendar basis.
   %
   % This function is a wrapper around bfra.getevents to detect recession events
   % on an annual basis, passing one year of a multi-year timeseries of T, Q,
   % and R at a time to eventfinder, rather than passing the entire timeseries
   % to eventfinder. The main difference is that when one year of data is used
   % at a time, the Savitsky Golay measurement noise filter can be effectively
   % applied prior to passing the data to eventfinder, because that filter needs
   % information about the measurement variability. TODO: construct an adaptive
   % sgolay filter that adjusts the filter parameters on an annual (or shorter)
   % basis.
   %
   % Required inputs:
   %   T          =  nx1 array of dates
   %   Q          =  nxm array of daily flow in units m3/day, organized as calendar
   %                 years, meaning n/365 = # of years
   %   R          =  nxm array of daily rainfall in (mm/day?)
   %
   % Optional name-value inputs:
   %  qmin        =  minimum flow value, below which values are set nan
   %  nmin        =  minimum event length
   %  fmax        =  maximum # of missing values gap-filled
   %  rmax        =  maximum run of sequential constant values
   %  rmin        =  minimum rainfall required to censor flow
   %  rmconvex    =  remove convex derivatives
   %  rmnochange  =  remove consecutive constant derivates
   %  rmrain      =  remove rainfall
   %
   %  opts        =  structure containing the fields listed above, in lieu of
   %                 entering them individually
   %
   % Note: flow comes in as m3/day/day
   %
   % See also: getevents
   %
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [T, Q, R, opts] = parseinputs(T, Q, R, mfilename, varargin{:});

   % Do some input checks to confirm the data is compatible with annual option
   [T, Q, R, numyears] = prepinput(T, Q, R);

   % Save the input data
   Events.inputTime = T;
   Events.inputFlow = Q;
   Events.inputRain = R;

   % Compute the number of timesteps per year
   numsteps = size(Q,1)/numyears;

   % Reshape the input lists to matrices
   if mod(numyears,1) == 0
      Qmat = reshape(Q,numsteps,numyears);    % flow, one column each year
      Rmat = reshape(R,numsteps,numyears);    % rain, one column each year
      Tmat = reshape(T,numsteps,numyears);    % calendar, one column each year
   else
      % Assume data is already in matrix form
      Qmat = Q;
      Rmat = R;
      Tmat = T;
   end

   % Initialize output structure and output arrays
   Qsave = nan(size(Qmat));
   Rsave = nan(size(Qmat));
   tsave = nan(size(Qmat));
   Etags = nan(size(Qmat));
   Count = 0; % initialize event counter

   % Compute the recession constants
   for thisYear = 1:numyears

      if all(isnan(Qmat(:,thisYear)))
         continue;
      end

      thisYearTime = Tmat(:,thisYear);
      thisYearFlow = Qmat(:,thisYear);
      thisYearRain = Rmat(:,thisYear);

      % Detect events for this year
      [thisYearEvents,thisYearInfo] = bfra.getevents( ...
         thisYearTime, thisYearFlow, thisYearRain, opts);

      % For each event, compute q, dqdt and fit a,b
      numEvents = numel(thisYearInfo.istart);
      for thisEvent = 1:numEvents

         % Get the start/end index on the annual calendar
         si = thisYearInfo.istart(thisEvent);
         ei = thisYearInfo.istop(thisEvent);

         eventQ = thisYearEvents.eventFlow(si:ei);
         eventT = thisYearEvents.eventTime(si:ei);
         eventR = thisYearEvents.eventRain(si:ei);

         % If no flow was returned, continue
         if all(isnan(eventQ)); continue; else
            Count = Count+1;
         end

         % Collect all data for the point-cloud
         Qsave( si:ei,thisYear ) = eventQ;
         Rsave( si:ei,thisYear ) = eventR;
         tsave( si:ei,thisYear ) = eventT;
         Etags( si:ei,thisYear ) = Count;
      end

      % pause to look at the fits
      if opts.plotevents == true
         hEvents = bfra.eventplotter(thisYearTime, thisYearFlow, ...
            thisYearRain, thisYearInfo, 'plotevents', true, ...
            'eventTags', 1);
         
         set(hEvents.ax(1), 'YScale', 'log')
         
         sprintf('all events fitted for %d',thisYear); pause; close all
      end
      
      % Concatenate Info
      if thisYear == 1
         Info = thisYearInfo;
      else
         thisYearInfo = updateinfo(thisYearInfo, thisYear);
         Info = catstructfields(1, Info, thisYearInfo);
      end
   end

   [ndays,numyears] = size(Qsave);
   Events.eventTime = reshape(tsave, ndays*numyears, 1);
   Events.eventFlow = reshape(Qsave, ndays*numyears, 1);
   Events.eventRain = reshape(Rsave, ndays*numyears, 1);
   Events.eventTags = reshape(Etags, ndays*numyears, 1);
   
   debug = false;
   if debug == true
      figure; plot(T(1:720), Q(1:720), 'o'); hold on;
      plot(T(thisYearInfo.imaxima), Q(thisYearInfo.imaxima), 'o')
   end
end

function thisYearInfo = updateinfo(thisYearInfo, thisYear)
   % Adjust the indices in Info to be relative to the multi-year timeseries
   fields = fieldnames(thisYearInfo);
   for f = fields(:).'
      if strncmp(f, 'i', 1)
         thisYearInfo.(f{:}) = thisYearInfo.(f{:}) + ...
            thisYearInfo.datalength * (thisYear-1) - 1;
      end
   end
end

function [T,Q,R,numyears] = prepinput(T,Q,R)
   % PREPINPUT remove leap inds and determine number of years.

   leapidx = month(T)==2 & day(T)==29;
   T(leapidx) = [];
   Q(leapidx) = [];
   R(leapidx) = [];
   numyears = numel(T)/365;

   assert(numyears == round(numyears), 'complete annual timeseries required');
end

%% INPUT PARSER
function [T, Q, R, opts] = parseinputs(T, Q, R, mfilename, varargin)

   parser = inputParser;
   parser.FunctionName = ['bfra.' mfilename];
   parser.StructExpand = true;

   parser.addRequired('T', @(x) isnumeric(x) | isdatetime(x));
   parser.addRequired('Q', @(x) isnumeric(x) & numel(x)==numel(T));
   parser.addRequired('R', @isnumeric);

   parser.addParameter('qmin', 1, @isnumericscalar);
   parser.addParameter('nmin', 4, @isnumericscalar);
   parser.addParameter('fmax', 2, @isnumericscalar);
   parser.addParameter('rmax', 2, @isnumericscalar);
   parser.addParameter('rmin', 0, @isnumericscalar);
   parser.addParameter('cmax', 2, @isnumericscalar);
   parser.addParameter('rmconvex', false, @islogical);
   parser.addParameter('rmnochange', true, @islogical);
   parser.addParameter('rmrain', false, @islogical);
   parser.addParameter('pickevents', false, @islogical);
   parser.addParameter('plotevents', false, @islogical);
   parser.addParameter('asannual', false, @islogical);

   parser.parse(T, Q, R, varargin{:});
   opts = parser.Results;

   if isempty(R)
      R = zeros(size(Q));
   end

   % Convert datetime to double if datetime was passed in
   T = todatenum(T);
end