function [ data_out, dates_out ] = rmleapinds( data,dates,varargin)
%RMLEAPINDS removes the feb 29 indices of data
%
%  [data_out, dates_out] = rmleapinds(data,dates) removes leap inds (feb 29)
%  from data and dates.
%
%  [data_out, dates_out] = rmleapinds(data,dates,'legacy') uses a legacy format
%  for backward compatibility.
%
%   Inputs  
%     data_in  : a column or row matrix of data
%     dates    : matlab formatted datenums
% 
%   Outputs 
%     data_out : same as data_in but with feb 29 removed
% 

if nargin>2
   if strcmp(varargin{1},'legacy')
      [ data_out,dates_out ] = rmleapinds_legacy( data_in,t ); return;
   else; error('unknown input');
   end
end

if nargin == 1
   if istimetable(data)
      data  = renametimetabletimevar(data);
      dates = data.Time;
   else
      dates = data; % assume we are removing feb29 from a calendar
   end
end

% make sure the data are as columns
if isrow(data)
   data = data';
end
if isrow(dates)
   dates = dates';
end
if size(data,1) ~= size(dates,1)
   data = data';
end

% if transpose didn't work, issue an error message
assert(size(data,1) == size(dates,1),                                   ...
   'data and dates must be oriented as columns with dates down the rows');

if isdatetime(dates)
   feb29 = month(dates) == 2 & day(dates) == 29;
else
   % dates     = dates(:);
   datesv = datevec(dates);
   feb29 = datesv(:,2) == 2 & datesv(:,3) == 29;
end

if ismatrix(data)
   data_out    = data(~feb29,:);
   dates_out   = dates(~feb29,:);
elseif ndims(data) == 3
   data_out    = data(~feb29,:,:);
   dates_out   = dates(~feb29,:,:);
end

% I think I had it this way because it works for both 2-d and 3-d arrays,
% but a better method would be to reshape data and/or make dates the same
% size as data
% data_out(feb29,:,:)     =   [];
% dates_out(feb29,:,:)    =   [];


function [ data_out,dates_out ] = rmleapinds_legacy( data_in,t )
%RMLEAPINDS removes the feb 29 indices of data
% 
%   Inputs
%     data_in  : a column or row matrix of data
%     t        : time matrix same size as data

%   Outputs 
%     data_out : same as data_in but with feb 29 removed

if isdatetime(t)
   t = datenum(t);
end

feb29 = find(t(:,2) == 2 & t(:,3) == 29);

data_out = data_in;
data_out(feb29,:,:) = [];

t = datevec(t);
dates_out(feb29,:) = [];

