function varargout = loadExampleData(varargin)
   %LOADEXAMPLEDATA Load toolbox example data.

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
      load(fullfile(datapath, 'annualdata.mat'),'Data');
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
