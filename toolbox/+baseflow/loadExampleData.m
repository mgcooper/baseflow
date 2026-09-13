function varargout = loadExampleData(varargin)
   %LOADEXAMPLEDATA Load toolbox example data.
   %
   % Syntax
   %
   %     [T, Q, R] = baseflow.loadExampleData()
   %     [T, Q, R, Data] = baseflow.loadExampleData('kuparuk')
   %
   % Description
   %
   %     [T, Q, R] = baseflow.loadExampleData() loads the daily streamflow
   %     example data from the toolbox data/ folder. It returns the time
   %     vector T (datenum), the daily flow Q, and the daily rain R.
   %
   %     [T, Q, R, Data] = baseflow.loadExampleData('kuparuk') also loads
   %     the annual Kuparuk basin data and returns it in Data. The function
   %     returns outputs in order, one per requested output.
   %
   % Example
   %
   %  Load the daily streamflow data and plot the hydrograph:
   %
   %     [T, Q, R] = baseflow.loadExampleData();
   %     plot(datetime(T, 'ConvertFrom', 'datenum'), Q)
   %     ylabel('Q (m^3 d^{-1})')
   %
   % See also: baseflow.getevents

   narginchk(0, 1);
   
   if nargin == 1
      option = validatestring(varargin{1}, {'kuparuk'}, mfilename, 'OPTION', 1);
   else
      option = 'default';
   end
   
   datapath = fullfile(baseflow.internal.basepath(), 'data');

   if isoctave
      load(fullfile(datapath, 'dailyflow_octave.mat'), 'T', 'Q', 'R');
      T = datenum(T); %#ok<*DATNM>
   else
      load(fullfile(datapath, 'dailyflow.mat'), 'T', 'Q', 'R');
      T = datenum(T); %#ok<*DATNM>
   end
   
   if strcmp(option, 'kuparuk')
      if isoctave
         load(fullfile(datapath, 'annualdata_octave.mat'),'Data');
         try
            Data = struct2table(Data);
         catch
         end
      else
         load(fullfile(datapath, 'annualdata.mat'),'Data');
      end
   else
      Data = [];
   end
   
   switch nargout
      case 1
         varargout{1} = T;
      case 2
         [varargout{1:nargout}] = deal(T, Q);
      case 3
         [varargout{1:nargout}] = deal(T, Q, R);
      case 4
         [varargout{1:nargout}] = deal(T, Q, R, Data);
   end
end
