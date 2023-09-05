function tf = istablelike(T)
   %ISTABLELIKE Return true if input T is a table or timetable.
   tf = istable(T) | istimetable(T);
end