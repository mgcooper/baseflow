function [data_out,dates_out] = padtimeseries(data,dates,padstart,padend,dt)
%PADTIMESERIES pads timeseries data with nan from padstart to beginning of
%data and from end of data to padend
%   Inputs:     data        =   timeseries of monotonically increasing data
%               dates       =   vector of datenums corresponding to data
%               padstart    =   date you want to start the padding
%               padend      =   date you want to end the padding

%   Outputs:    data_out    =   padded data
%               dates_out   =   padded dates 

% get the size of the data
[m,n] = size(data);

wasdatetime = isdatetime(dates);
if wasdatetime == true
   dates = datenum(dates);
end

% make sure the padstart/padend are dates
padstart = datenum(padstart);
padend   = datenum(padend);
dates    = datenum(dates);

% get the missing dates 
missing_datesi = padstart:dt:dates(1)-dt;
missing_datesf = dates(end)+dt:dt:padend;

% make a nan vector same size
numpadi = length(missing_datesi);
numpadf = length(missing_datesf);

% pad the data
data_out  = [nan(numpadi,n);data;nan(numpadf,n)];
dates_out = [missing_datesi';dates;missing_datesf'];

if wasdatetime == true
   dates_out = datetime(dates_out,'ConvertFrom','datenum');
end

