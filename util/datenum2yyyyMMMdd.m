function yyyyMMMdd = datenum2yyyyMMMdd(date)
   
   date        = datetime(mean(date),'ConvertFrom','datenum');
   yyyyMMMdd   = sprintf('%d_%d_%d',year(date),month(date),day(date));