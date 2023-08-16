function varargout = prepalttrend(Calm,T,Q,Qb,Sb,Db,sigDb,varargin)
%PREPALTTREND prep data for fitting linear trend to active layer thickness data
% 
% Syntax
% 
%  Data = PREPALTTREND(X) description
%  Data = PREPALTTREND(X,'name1',value1) description
%  Data = PREPALTTREND(X,'name1',value1,'name2',value2) description
% 
% Example
%  
% 
% Matt Cooper, 03-Dec-2022, https://github.com/mgcooper
% 
% See also

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% PARSE INPUTS
[Calm, T, Q, Qb, Sb, Db, sigDb, removenans] = parseinputs(Calm, T, Q, Qb, ...
   Sb, Db, sigDb, varargin{:});

% MAIN FUNCTION
[Q,T] = bfra.util.padtimeseries(Q,T,datenum(year(T(1)), 1, 1), ...
   datenum(year(T(end)), 12, 31), 1);
Data = timetable(Q, 'RowTimes', T);
Data = retime(Data, 'regular', 'mean', 'TimeStep', calyears(1));

% This lines up the baseflow water years with the calm end-of summer data
% Data = retime(Data,'yearly','previous');
% %Data = Data(2:end,:);

Data = addvars(Data, Qb, Sb, Db);
Data = synchronize(Data, Calm, Data.Time, 'fillwithmissing');
sigDb = Data.Db .* sigDb; % convert relative to absolute uncertainty
Data = addvars(Data, sigDb);

if removenans == true
   inanC = isnan(Data.Dc);%  | isnan(Data.Q);
   DataC = Data(~inanC, :);
else
   % Use this to require the first year is 1990
   % DataC = Data(find(year(Data.Time)==1990):end, :);
   
   iyear = find(year(Data.Time)==1990);
   if isempty(iyear)
      iyear = 1;
   end
   DataC = Data(iyear:end,:);
end

DataG = Data(find(year(Data.Time)==2001):end, :);

varargout{1} = Data;
switch nargout
   case 2
      varargout{2} = DataC;
   case 3
      varargout{2} = DataC;
      varargout{3} = DataG;
end

%% INPUT PARSER
function [Calm, T, Q, Qb, Sb, Db, sigDb, removenans] = parseinputs( ...
   Calm, T, Q, Qb, Sb, Db, sigDb, varargin)

parser = inputParser;
parser.FunctionName = 'bfra.util.prepalttrend';
parser.addRequired('Calm', @bfra.validation.istablelike);
parser.addRequired('T', @bfra.validation.isdatelike);
parser.addRequired('Q', @bfra.validation.isnumericvector);
parser.addRequired('Qb', @bfra.validation.isnumericvector);
parser.addRequired('Sb', @bfra.validation.isnumericvector);
parser.addRequired('Db', @bfra.validation.isnumericvector);
parser.addRequired('sigDb', @bfra.validation.isnumericvector);
parser.addParameter('rmnan', true, @bfra.validation.islogicalscalar);

parser.parse(Calm, T, Q, Qb, Sb, Db, sigDb, varargin{:});
removenans = parser.Results.rmnan;
