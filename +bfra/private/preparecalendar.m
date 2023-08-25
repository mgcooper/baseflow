function [T,Q,R,numyears,timestep] = preparecalendar(T,Q,R)
% PREPINPUT remove leap inds, determine timestep, determine number of years.

% This was the original check in getevents, then moved to wrapevents, but it's
% not necessary there so I simplified it and moved it here for future conversion
% to a proper function that allows more flexible inputs to the core algorithm
% e.g. including leap inds, irregular calendars, water year vs calendar year,
% non-daily data, etc.

hasleap = any(month(T)==2 & day(T)==29);

if hasleap
   try
      % check if the input data includes leap inds
      hasleap = month(T)==2 & day(T)==29;
      
      % if the time is regular, we can get the timestep here
      if isregular(timetable(T,'RowTimes',T),'time')
         timestep = T(2)-T(1);
      else
         % if leap inds are already removed, the time won't be regular, so only
         % warn if time includes leap inds
         if any(hasleap)
            warning('irregular calendar, results may be inconsistent')
         end
      end
      
      if any(hasleap)
         warning('removing leap inds');
         T(hasleap) = []; Q(hasleap) = []; R(hasleap) = [];
      end
   catch e
      throwAsCaller(e)
   end
end

% this is correct
numyears = numel(T)/365;

% % both of these fail if water years are passed in   
% numyears = numel(unique(year(T)));
% 
% firstyear   = year(T(1));
% lastyear    = year(T(end));
% numyears    = lastyear-firstyear+1;