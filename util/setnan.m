function [ dataout ] = setnan( datain,nanvalORinds )
   %SETNAN sets logical indices in data to nan
   %   Detailed explanation goes here
   
   % Note: below I detect which columns are numeric but i don't convert
   % from cell to numeric so if a table is imported with mixed data and it
   % should all be numeric, this won't work as expected (e.g. when reading
   % in new data for the first time and setting a known value nan)
   
   wastable    = false;    % was a table
   wasttable   = false;    % was a timetable
   
   if istable(datain)
      wastable    = true;
      inumeric    = cellfun(@isnumeric,table2cell(datain(1,:)));
      dataout     = table2array(datain(:,inumeric));
      props       = datain.Properties;
   elseif istimetable(datain)
      wasttable   = true;
      Time        = datain.Time;
      props       = datain.Properties;    % get props before converting
      iTime       = datain.Properties.DimensionNames;
      datain      = timetable2table(datain);
      datain      = datain(:,2:end);      % remove time column
      inumeric    = cellfun(@isnumeric,table2cell(datain(1,:)));
      dataout     = table2array(datain(:,inumeric));
      % i was gonna use iTime to remove the time column but only works if
      % it is always called 'Time'
   else
      dataout     = datain;
   end
   
   nanval = nanvalORinds;
   
   % update jan 2022, commented out stuff shouldn't be needed with new table
   % checks above
   
   % assume nanval is a logical vector denoting where to set data_in nan
   if islogical(nanval)
      
      if numel(datain)==numel(nanval)
         
         dataout(nanval)      = nan;
         
      elseif size(datain,1) == size(nanval,1) && size(datain,2) ~= size(nanval,2)
         
         dataout(nanval,:)    = nan;
         
      elseif size(datain,2) == size(nanval,2) && size(datain,1) ~= size(nanval,1)
      
         dataout(:,nanval)    = nan;
         
      end
      
   elseif isscalar(nanval)
      % assume nanval is a scalar value and I want to set all elements
      % equal to nanval to nan
      naninds             =   dataout == nanval;
      dataout(naninds)    =   nan;
   end
   
   if wastable == true
      datain(:,inumeric)  = array2table(dataout);
      dataout             = datain;
   end
   
   if wasttable == true
      datain(:,inumeric)  = array2table(dataout);
      dataout             = datain;
      dataout             = table2timetable(dataout,'RowTimes',Time);
      dataout.Properties  = props;
   end
   
end


% %     if istimetable(dataout) || istable(dataout)
%       %         naninds = find(nanval(:,1));
%       %         for i = 1:height(dataout)
%       %             if ismember(i,naninds)
%       %                 dataout(i,:) = table(nan);
%       %             end
%       %         end
%       %     else
%       dataout(nanval)    = nan;
%       %     end