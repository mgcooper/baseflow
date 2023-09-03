function tf = istablelike(T)
%ISTABLELIKE returns true if input T is a table or timetable. will be deprecated
%on upgrade to R2021 or whichever release has istabular
tf = istable(T) | istimetable(T);