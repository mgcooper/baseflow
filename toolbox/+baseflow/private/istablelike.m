function tf = istablelike(T)
   %ISTABLELIKE Return true if input T is a table or timetable.
   %
   %  tf = istablelike(T) returns true if T is a table or a timetable.
   tf = istable(T) | istimetable(T);
end