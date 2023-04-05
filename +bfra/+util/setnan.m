function [ DataOut ] = setnan(Data,varargin)
%SETNAN sets logical indices in Data to nan

% TODO: support for structs and cells, also I might be able to simplify the
% table parts using replacevars like in the new set all nan section

%----------------------------------------------------------------------
p              = magicParser;
p.FunctionName = mfilename;

p.addRequired( 'Data'                                 );
p.addOptional( 'nanval',   nan,   @(x)isnumeric(x)    );
p.addOptional( 'naninds',  false, @(x)islogical(x)    );

p.parseMagically('caller');

nanval   = p.Results.nanval;
naninds  = p.Results.naninds;
%----------------------------------------------------------------------

% Note: below I detect which columns are numeric but i don't convert
% from cell to numeric so if a table is imported with mixed data and it
% should all be numeric, this won't work as expected (e.g. when reading
% in new data for the first time and setting a known value nan)

wastable = istable(Data);           % was a table
wastimetable = istimetable(Data);   % was a timetable

% if only the Data was passed in, set all values nan
if nargin == 1
   DataOut = nan(size(Data));
   if wastable || wastimetable
      DataOut = replacevars(Data,Data.Properties.VariableNames,DataOut);
      return
   end
end


% if a table was passed in, prep it for replacement
if wastable
   inumeric    = cellfun(@isnumeric,table2cell(Data(1,:)));
   DataOut     = table2array(Data(:,inumeric));
   props       = Data.Properties;
elseif wastimetable
   Time        = Data.Time;
   props       = Data.Properties;    % get props before converting
   iTime       = Data.Properties.DimensionNames;
   Data        = timetable2table(Data);
   Data        = Data(:,2:end);      % remove time column
   inumeric    = cellfun(@isnumeric,table2cell(Data(1,:)));
   DataOut     = table2array(Data(:,inumeric));
   % i was gonna use iTime to remove the time column but only works if
   % it is always called 'Time'
else
   DataOut     = Data;
end

% determine if nanval or naninds will be used, if the latter, assign naninds to
% nanval b/c the final part below uses nanval for everything
useval = false;
useinds = false;
if isscalar(naninds) && naninds == false && ~isnan(nanval)
   % assume naninds is the default scalar "false"
   useval = true;
elseif isempty(nanval) || isscalar(nanval) && isnan(nanval)
   % assume nanval is the default scalar "nan"
   useinds = true;
   nanval = naninds;
end


% update jan 2022, commented out stuff shouldn't be needed with new table
% checks above

% assume nanval is a logical vector denoting where to set Data nan, but we need
% to determine if the vector matches the size of Data or the size of the rows or
% columns of Data. For the latter, assume it should be applied to all rows/cols.
if useinds == true
   
   % we dont check if a scalar true is passed in because that makes no sense
   if numel(DataOut)==numel(nanval) 
      DataOut(nanval) = nan;
      
   elseif size(DataOut,1) == size(nanval,1) && size(DataOut,2) ~= size(nanval,2)
      DataOut(nanval,:) = nan;
      
   elseif size(DataOut,2) == size(nanval,2) && size(DataOut,1) ~= size(nanval,1)
      DataOut(:,nanval) = nan;   
   end
   
elseif useval == true
   % set all elements equal to nanval(s) to nan
   for n = 1:numel(nanval)
      DataOut(DataOut == nanval(n)) = nan;
   end
end

if wastable == true
   Data(:,inumeric)  = array2table(DataOut);
   DataOut           = Data;
end

if wastimetable == true
   Data(:,inumeric)  = array2table(DataOut);
   DataOut           = Data;
   DataOut           = table2timetable(DataOut,'RowTimes',Time);
   DataOut.Properties = props;
end


% if istimetable(dataout) || istable(dataout)
%    naninds = find(nanval(:,1));
%    for i = 1:height(dataout)
%       if ismember(i,naninds)
%          dataout(i,:) = table(nan);
%       end
%    end
% else
%    dataout(nanval) = nan;
% end
