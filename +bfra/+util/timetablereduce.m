function NewData = timetablereduce(Data,varargin)
%TIMETABLEREDUCE statistical reduction of timetable data to mean, stdv, and ci's
% 
% NewData = timetablereduce(Data,'keeptime',true) keeps the time column in the
% case of single vector input and returns the vector with new header 'mu'
% 
% See also stderr

%-------------------------------------------------------------------------------
p = magicParser;
p.FunctionName = mfilename;
p.addRequired( 'Data', @(x)istimetable(x));
p.addParameter('alpha', 0.32, @(x)isnumeric(x));
p.addParameter('keeptime', true, @(x)islogical(x));
p.parseMagically('caller');
alpha = p.Results.alpha; 
%-------------------------------------------------------------------------------
Data.Properties.DimensionNames{1} = 'Time';
Time = Data.Time;

% if the table has one column this returns the same data but renames the column
% header 'mu' and imputes nan for all other statistics. mainly for convencience
% if this function is used in a loop over tables of differing size, some of
% whcih may have only one column so data reduction is not meaningful but the
% table headers need to be consistent for other parts of the code
if width(Data) == 1 && keeptime == true
   NewData = Data;
   NewData.Properties.VariableNames = {'mu'};
   SE = nan(height(Data),1);
   CI = nan(height(Data),1);
   PM = nan(height(Data),1);
   sigma = nan(height(Data),1);
   NewData = addvars(NewData,SE,CI,PM,sigma);
   return
end

% compute mean, stderr, ci, etc
[SE,CI,PM,mu,sigma] = bfra.util.stderr(table2array(Data),'alpha',alpha); 
CIL = CI(:,1); CIH = CI(:,2);

if isscalar(mu)
   Time = mean(Time);
end

NewData = timetable(Time,mu,sigma,SE,CIL,CIH,PM);

% copy over properties (might not work, if fails, fix brace indexing)
if ~isempty(Data.Properties.VariableUnits)
   NewData.Properties.VariableUnits = Data.Properties.VariableUnits{1};
elseif ~isempty(Data.Properties.VariableContinuity)
   NewData.Properties.VariableContinuity = Data.Properties.VariableContinuity{1};
end


