function Meta = querymeta(Meta,varargin)
%QUERYMETA query bfra toolbox metadata structure
% 
% work in progress, may not be worth it
% 
% Syntax
% 
%  A = BFRA.QUERYMETA(Meta,'query',logicquery);
%  A = BFRA.QUERYMETA(___,'sort',sortquery);
% 
% Author: Matt Cooper, 24-Nov-2022, https://github.com/mgcooper

%------------------------------------------------------------------------------
% input parsing
%------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = 'bfra.querymeta';

addRequired(p,    'Meta',                 @(x)istable(x)    );
addParameter(p,   'query',    false,      @(x)ischar(x)     );
addParameter(p,   'sort',     nan,        @(x)ischar(x)     );

parse(p,Meta,varargin{:});

logicquery  = p.Results.query;
sortquery   = p.Results.sort;
   
% https://www.mathworks.com/help/matlab/matlab_prog/parse-function-inputs.html
%------------------------------------------------------------------------------

% idx = Meta
Meta = Meta(logicquery,:);












