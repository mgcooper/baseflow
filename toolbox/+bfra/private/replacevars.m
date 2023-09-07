function T = replacevars(T,VarNames,NewVars,varargin)
   %REPLACEVARS replace vars in table T with new vars.
   %
   % Syntax
   %
   %  T = REPLACEVARS(T,VarNames,NewVars) replaces columns with variable names
   %  VarNames with columns of NewVars. VarNames is a cell array of variable
   %  names that match values of T.Properties.VariableNames. NewVars is an array
   %  with second dimension (width) equal to numel(VarNames).
   %
   %  T = REPLACEVARS(T,VarNames,NewVars,'NewVarNames',NewVarNames) also
   %  replaces the VarNames with NewVarNames.
   %
   %
   % Matt Cooper, 29-Nov-2022, https://github.com/mgcooper
   %
   % See also: addvars, removevars

   %% input parsing
   p = inputParser;
   p.FunctionName = mfilename;
   p.CaseSensitive = false;
   p.KeepUnmatched = true;

   validVarNames = @(var) all(ismember(var, T.Properties.VariableNames));

   addRequired(p, 'T', @istablelike);
   addRequired(p, 'VarNames', validVarNames);
   addRequired(p, 'NewVars');
   addParameter(p,'NewVarNames', VarNames, @ischarlike);

   parse(p, T, VarNames, NewVars, varargin{:});

   %% function code

   % Remove the vars
   T = removevars(T, VarNames);

   % Create the new VariableNames property list before adding the new vars
   V = [T.Properties.VariableNames p.Results.NewVarNames];

   % Recursively add columns for the case of 2-d data
   for n = 1:size(NewVars, 2)
      T = addvars(T, NewVars(:, n));
   end

   % Assign the new VariableNames property list
   T.Properties.VariableNames = V;
end
