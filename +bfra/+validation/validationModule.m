function f = validationModule
%VALIDATIONMODULE validation function module
% 
%  f = validationModule; returns scalar struct array f containing function
%  handles to validate function inputs
% 
% Example
% f = bfra.validation.validationModule;
% f.validChar(1)
% f.validChar('a')
% f.validAxis(1)
% f.validAxis(gca)
% 
% @() Matt Cooper, 26-Apr-2023, https://github.com/mgcooper
% 
% See also


% Store all local functions in f, get the function names, convert to a struct
% array with function name fieldnames, and instantiate the functions
f = localfunctions;
f = structfun(@(x) x(),cell2struct(f,cellfun(@func2str,f,'uni',0),1),'uni',0);


% % explicit:
% f = localfunctions;
% funcnames = cellfun(@func2str,f,'uni',0);
% f = cell2struct(f,funcnames,1);
% for n = 1:numel(funcnames)
%    f.(funcnames{n}) = f.(funcnames{n})();
% end
% 
% % simplify by using cellfun:
% f = localfunctions;
% funcnames = cellfun(@func2str,f,'uni',0);
% f = cellfun(@(x) x(),f,'uni',0);
% f = cell2struct(f,funcnames,1);
% 
% % using structfun to avoid storing funcnames
% f = localfunctions;
% f = cell2struct(f,cellfun(@func2str,f,'uni',0),1);
% f = structfun(@(x) x(),f,'uni',0);
% 
% 
% This works (pass in the validationFunction and the argument), but
% tf = f.(validationFunction)(x) is still the fucntion handle, which isn't
% really what I want, but for reference:

% function tf = validationModule(validationFunction,x)
% f = localfunctions;
% f = cell2struct(f,cellfun(@func2str,f,'uni',0),1);
% tf = f.(validationFunction)();
% tf = tf(x);

end

function f = validAxis
f = @(x) isa(x,'matlab.graphics.axis.Axes');
end

function f = validErrorBar
f = @(x) isa(x,'matlab.graphics.chart.primitive.ErrorBar');
end

function f = validChar
f = @(x) ischar(x) ;
end

function f = validString
f = @(x) ischar(x) ;
end

function f = validCharLike
f = @(x) ischar(x) | isstring(x) | iscellstr(x) ;
end

function f = validDateLike
f = @(x) isdatetime(x) | isnumeric(x) & isvector(x);
end

function f = validDateTime
f = @(x) isdatetime(x) ;
end

function f = validNumericScalar
f = @(x) isnumeric(x) && isscalar(x) ;
end

function f = validNumericVector
f = @(x) isnumeric(x) && isvector(x) ;
end

function f = validNumericMatrix
f = @(x) isnumeric(x) && ismatrix(x) && ~isvector(x) ;
end

function f = validDoubleScalar
f = @(x) isa(x,'double') && isscalar(x) ;
end

function f = validDoubleVector
f = @(x) isa(x,'double') && isvector(x) ;
end

function f = validDoubleMatrix
f = @(x) isa(x,'double') && ismatrix(x) && ~isvector(x) ;
end

function f = validSingleScalar
f = @(x) isa(x,'single') && isscalar(x) ;
end

function f = validSingleVector
f = @(x) isa(x,'single') && isvector(x) ;
end

function f = validSingleMatrix
f = @(x) isa(x,'single') && ismatrix(x) && ~isvector(x) ;
end

function f = validLogicalScalar
f = @(x) islogical(x) && isscalar(x) ;
end

function f = validLogicalVector
f = @(x) islogical(x) && isvector(x) ;
end

function f = validLogicalMatrix
f = @(x) islogical(x) && ismatrix(x) && ~isvector(x) ;
end

function f = validTableLike
f = @(x) istable(x) | istimetable(x) ;
end