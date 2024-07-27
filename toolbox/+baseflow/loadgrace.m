function [Grace, Meta] = loadgrace(varargin)
   %LOADGRACE Load grace data for basin in baseflow basin database.
   %
   % Grace data should be in cm/timestep
   %
   % See also: baseflow.loadghcnd, baseflow.loadflow, baseflow.loadcalm

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % fast exit if toolbox not configured for data functions
   if ~isenv('BASEFLOW_DATA_PATH')
      error('BASEFLOW_DATA_PATH environment variable not set')
   end

   % parse inputs
   [basinname, t1, t2, ~] = parseinputs(varargin{:});

   % load the old data note: an earlier version used the grace_minmax.mat file
   load(fullfile(getenv('BASEFLOW_DATA_PATH'), 'grace', 'grace_basins_v0.mat'), 'Grace')

   % the new data
   % load(filedata,'Grace');

   Meta = Grace.meta;

   if strcmp(basinname,'all')    % return all the basins
      % need to add options to regularize (interp to a regular monthly cal)
      % or trim to t1:t2
      return
   else

      % use ismember for exact match not contains
      allnames = lower(Meta.name);
      idx = ismember(allnames,lower(basinname));

      if sum(idx) == 0
         error('basin not found, may not have Grace for this basin, otherwise check name');
      else

         %       % temporary hack to get the 2022 data
         %       if strcmp(basinname,'KUPARUK R NR DEADHORSE AK')
         %          load([pathdata 'grace_kuparuk'],'Grace');
         %          Grace = renamevars(Grace,'Scsr','S');
         %          Grace = removevars(Grace,'Sjpl');
         %
         %          % the other data is normalized to 2002-2020, but this data is
         %          % not, so do that here
         %          Grace.S = Grace.S-nanmean(Grace.S);
         %
         %       else
         %          Time = tocolumn(Grace.time);
         %          S = tocolumn(Grace.Sa_avg(idx,:));
         %          Grace = timetable(S,'RowTimes',Time);
         %       end

         % % delete this and replace w/above if using 2022 data
         Time = tocolumn(Grace.time);
         S = tocolumn(Grace.Sa_avg(idx,:));
         Grace = timetable(S,'RowTimes',Time);
         % %

         Meta = Meta(idx,:);

         % if t1/t2 requested, retime to a regular monthly calendar
         if ~isnat(t1)
            Time = t1:calmonths(1):t2;
            Grace = retime(Grace,'monthly','linear');
            Grace = retime(Grace,Time,'fillwithmissing');
         end

         Grace.Properties.VariableUnits = {'cm'};

         % % for now I return monthly S, but this is what is returned in BFRA_drive
         %          % Pull out the data
         %          G.T = Grace.time;
         %          G.S = Grace.Sa_avg(idx,:);
         %          G.SL = Grace.Smin(idx,:);
         %          G.SH = Grace.Smax(idx,:);
         %          G.TL = Grace.tmin(idx,:);
         %          G.TH = Grace.tmax(idx,:);
         %          G.Tref = Grace.time_ref;
         %          Grace = G;
      end
   end
end

%% INPUT PARSER
function [basinname, t1, t2, regularize] = parseinputs(varargin)

   parser = inputParser;
   parser.FunctionName = 'baseflow.loadgrace';
   parser.addOptional('basinname','all',@ischar);
   parser.addParameter('t1',NaT,@(x) isdatetime(x) | isnumeric(x));
   parser.addParameter('t2',NaT,@(x) isdatetime(x) | isnumeric(x));
   parser.addParameter('regularize', true, @ischar);
   parser.parse(varargin{:});

   basinname = parser.Results.basinname;
   t1 = parser.Results.t1;
   t2 = parser.Results.t2;
   regularize = parser.Results.regularize;

   if ~isdatetime(t1) %#ok<*NODEF>
      t1 = datetime(t1,'ConvertFrom','datenum');
      t2 = datetime(t2,'ConvertFrom','datenum');
   end
end
