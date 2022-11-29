function yyyyMMMdd = datenum2yyyyMMMdd(date)
   if ~isdatetime(date)
      date     = datetime(mean(date),'ConvertFrom','datenum');
   end
   yyyyMMMdd   = sprintf('%d_%d_%d',year(date),month(date),day(date));