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

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = 'bfra.util.prepalttrend';
p.addRequired( 'Calm', @(x)bfra.validation.istablelike(x));
p.addRequired( 'T', @(x)bfra.validation.isdatelike(x));
p.addRequired( 'Q', @(x)bfra.validation.isnumericvector(x));
p.addRequired( 'Qb', @(x)bfra.validation.isnumericvector(x));
p.addRequired( 'Sb', @(x)bfra.validation.isnumericvector(x));
p.addRequired( 'Db', @(x)bfra.validation.isnumericvector(x));
p.addRequired( 'sigDb', @(x)bfra.validation.isnumericvector(x));
p.addParameter('rmnan', true, @(x)bfra.validation.islogicalscalar(x));

parse(p,Calm,T,Q,Qb,Sb,Db,sigDb,varargin{:});
removenans = p.Results.rmnan;
%------------------------------------------------------------------------------

[Q,T] = bfra.util.padtimeseries(Q,T,datenum(year(T(1)),1,1), ...
   datenum(year(T(end)),12,31),1);
Data = timetable(Q,'RowTimes',T);
Data = retime(Data,'regular','mean','TimeStep',calyears(1));

% I am not sure about this ... I think this is for water years? either way it
% must be to ensure the baseflow matches the calm data, but I commented it out
% Data = retime(Data,'yearly','previous');
% %Data = Data(2:end,:);

Data = addvars(Data,Qb,Sb,Db);
Data = synchronize(Data,Calm,Data.Time,'fillwithmissing');
sigDb = Data.Db.*sigDb; % convert relative to absolute uncertainty
Data = addvars(Data,sigDb);

if removenans == true
   inanC = isnan(Data.Dc);%  | isnan(Data.Q);
   DataC = Data(~inanC,:);
else
   DataC = Data(find(year(Data.Time)==1990):end,:);
end

DataG = DataC(find(year(DataC.Time)==2002):end,:);

varargout{1} = Data;
switch nargout
   case 2
      varargout{2} = DataC;
   case 3
      varargout{2} = DataC;
      varargout{3} = DataG;
end
