function [T, Q, R] = loadExampleData()
   %LOADEXAMPLEDATA Load toolbox example data.

   datapath = fullfile(baseflow.internal.basepath(), 'data');

   if isoctave
      load(fullfile(datapath, 'dailyflow_octave.mat'), 'T', 'Q', 'R');
      T = datenum(T); %#ok<*DATNM>
   else
      load(fullfile(datapath, 'dailyflow.mat'), 'T', 'Q', 'R');
      T = datenum(T); %#ok<*DATNM>
   end
end
