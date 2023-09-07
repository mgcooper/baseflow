function [data_out,dates_out] = padtimeseries(data,dates,padstart,padend,dt)
   %PADTIMESERIES Pad nan from padstart to first date and last date to padend.
   %
   % [data_out,dates_out] = padtimeseries(data,dates,padstart,padend,dt) appends
   % (pads) nan values from date PADSTART to the first date in DATES and from
   % the last date in DATES to PADEND. DATA and DATES must be the same size.
   %
   % Inputs
   %
   % data        =   timeseries of data
   % dates       =   vector of datenums for each value in data
   % padstart    =   date to start the padding
   % padend      =   date to end the padding
   %
   % Outputs
   %
   % data_out    =   padded data
   % dates_out   =   padded dates
   %
   % See also padtimetable

   % get the size of the data
   [~,n] = size(data);

   wasdatetime = isdatetime(dates);
   if wasdatetime == true
      dates = datenum(dates); %#ok<*DATNM> 
   end

   % convert padstart/padend to datenums
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
end
