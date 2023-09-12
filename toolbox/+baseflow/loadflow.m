function [Flow,Meta] = loadflow(basinname,varargin)
   %LOADFLOW Load timeseries of streamflow and metadata for basin.
   %
   % Syntax
   %
   %     [Flow,Meta] = loadflow(basinname,varargin)
   %
   % Description
   %
   %     [Flow,Meta] = loadflow(basinname) returns table Flow containing
   %     discharge data for basin basinname and metadata about the site and
   %     catchment Meta.
   %
   %     [Flow,Meta] = loadflow(___,'t1',t1,'t2',t2) returns table Flow for the
   %     time period bounded by datetimes t1 and t2.
   %
   %     [Flow,Meta] = loadflow(___,'units',units) converts Flow from the
   %     standard units m3/s to user-specified units. Options are available
   %     using tab-completion.
   %
   %     [Flow,Meta] = loadflow(___,'gapfill',true) gap-fills missing data using
   %     an auto-regressive fit to annual data values.
   %
   % See also: loadcalm, loadbounds
   %
   % Matt Cooper, 20-Feb-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % fast exit if toolbox not configured for data
   if ~isenv('BASEFLOW_DATA_PATH')
      error('BASEFLOW_DATA_PATH environment variable not set')
   end

   % PARSE INPUTS
   [basinname, t1, t2, units, gapfill, ~] = parseinputs(basinname, varargin{:});

   % load the flow data
   load(fullfile( ...
      getenv('BASEFLOW_DATA_PATH'), 'flow', 'flow_prepped.mat'), 'Flow');

   % check for categorical station name
   if iscategorical(basinname); basinname = char(basinname); end

   % find the flow data (for exact match use ismember not contains)
   allnames = lower(Flow.Meta.name);
   istation = find(ismember(allnames,lower(basinname)));
   Meta = Flow.Meta(istation,:);

   %%%%%%%%%%%%%%%% new method that uses the raw .csv files
   % sta = Meta.station{:};
   % [Q,Time] = readflow(sta);
   %%%%%%%%%%%%%%%% new method that uses the raw .csv files

   %%%%%%%%%%%%%%%% old method that used the database
   Q = Flow.Q(:,istation);
   Time = Flow.T;
   %%%%%%%%%%%%%%%% old method that used the database

   if isnat(t1)
      si = find(~isnan(Q),1,'first');
      ei = find(~isnan(Q),1,'last');
      ok = si:ei;
   else
      ok = isbetween(Time,t1,t2);
   end
   % the t1/t2 method might remove the need for padding/trimming

   Q = Q(ok);
   Time = Time(ok);
   Flow = timetable(Time,Q);

   % experimental - gap fill. should prob add this to a timetable function
   if gapfill == true
      numyears = height(Flow)/365;
      Q = transpose(reshape(Flow.Q,365,numyears));
      Q = reshape(transpose(fillgaps(Q)),numyears*365,1);
      Q(Q<0) = 0; Flow.Q = Q;
   end
   % (kuparuk flow is missing the last two months (Nov/Dec 2020))

   if ~isnan(units)
      cms2cmd = @(x) x.*86400;
      aream2 = Meta.darea.*1e6;
      switch units
         case 'mm/d'
            Flow.Q = cms2cmd(Flow.Q)./aream2.*1000;
         case 'cm/d'
            Flow.Q = cms2cmd(Flow.Q)./aream2.*100;
         case 'm/d'
            Flow.Q = cms2cmd(Flow.Q)./aream2;
         case 'mm/y'
            Flow.Q = cms2cmd(Flow.Q)./aream2.*1000.*365.25;
         case 'cm/y'
            Flow.Q = cms2cmd(Flow.Q)./aream2.*100.*365.25;
         case 'm/y'
            Flow.Q = cms2cmd(Flow.Q)./aream2.*365.25;
         case 'm3/d'
            Flow.Q = cms2cmd(Flow.Q);
         case 'm3/y'
            Flow.Q = cms2cmd(Flow.Q)*365.25;
         case 'km3/y'
            Flow.Q = cms2cmd(Flow.Q)*365.25./1e9; % Gt/yr
      end

      % keep the original m3/s
      %if addvar == true
      Qm3s = Q;
      Flow = addvars(Flow,Qm3s);
      units = {units,'m3/s'};
      %end
   else
      units = {'m3/s'};
   end

   % flow is in m3/s, so set that here
   Flow.Properties.VariableUnits = units;
end

%% LOCAL FUNCTIONS
function [Q,Time] = readflow(sta)

   filename = [sta '.csv'];

   % check the rhbn database:
   pathdata = '/Users/coop558/mydata/interface/recession/rhbn/data/';
   datadirs = {'rhbn99','rhbnN','rhbnU'};
   for n = 1:numel(datadirs)
      filelist = getlist([pathdata datadirs{n} '/'],'*.csv');
      allfiles = {filelist.name};
      fileindx = find(ismember(allfiles,filename));
      if ~isempty(fileindx)
         break
      end
   end

   % if not found, check the usgs database:
   if isempty(fileindx)

      pathdata = '/Users/coop558/mydata/interface/recession/gagesII/data/';
      datadirs = {'ref','other','nonref'};
      for n = 1:numel(datadirs)
         filelist = getlist([pathdata datadirs{n} '/'],'*.csv');
         allfiles = {filelist.name};
         fileindx = find(ismember(allfiles,filename));
         if ~isempty(fileindx)
            break;
         end
      end

   end

   if isempty(fileindx)
      error('file not found')
   end

   Data  = readtable([pathdata datadirs{n} '/' filename]);
   Time  = datetime(Data.Year,Data.Month,Data.Day);
   Q     = Data.Value;
   Data  = timetable(Time,Q);
   Data  = retime(Data,'daily','fillwithmissing');
   Data  = rmleapinds(Data);
   Q     = Data.Q;
   Time  = Data.Time;

   %    % i used this to confirm the new data matches the old data:
   %    idx = isbetween(data.Time,Flow.Time(1),Flow.Time(end));
   %    figure; scatter(Flow.Q,data.Q(idx),'filled'); addOnetoOne;

   %    % but this also reveals that i rmeoved leap inds so feb 28-mar 1
   %    dQ/dt is incorrect if any end up used in the analysis
end

%% INPUT PARSER
function [basinname, t1, t2, units, gapfill, addvar] = parseinputs( ...
      basinname, varargin)

   parser = inputParser;
   parser.FunctionName = 'baseflow.loadflow';
   parser.PartialMatching = true;

   parser.addRequired('basinname', @ischar);
   parser.addParameter('t1', NaT, @isdatelike);
   parser.addParameter('t2', NaT, @isdatelike);
   parser.addParameter('units', NaN, @ischar);
   parser.addParameter('gapfill', false, @islogical);
   parser.addParameter('addvar', false, @ischar);

   parser.parse(basinname, varargin{:});

   basinname = parser.Results.basinname;
   gapfill = parser.Results.gapfill;
   addvar = parser.Results.addvar;
   units = parser.Results.units;
   t1 = parser.Results.t1;
   t2 = parser.Results.t2;

   if ~isdatetime(t1)
      t1 = datetime(t1, 'ConvertFrom', 'datenum');
      t2 = datetime(t2, 'ConvertFrom', 'datenum');
   end
end
