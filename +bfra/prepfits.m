function [x,y,logx,logy,w,ok] = prepfits(q,dqdt,varargin)
%PREPFITS preps q and -dq/dt for event-scale fitting
%
% Syntax
% 
%  [x,y,logx,logy,weights,success] = prepfits(q,dqdt,varargin)
% 
% Required inputs
% 
%     q        =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%     dqdt     =  discharge rate of change (L T^-2)
%
% Optional name-value inputs
% 
%     weights  =  nx1 double of weights for the fitting algorithm
%     mask     =  nx1 logical mask to exclude values from fitting
%
%  note: dqdt comes in as its actual value i.e. negative
%
%  See also: fitab

%-------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = 'bfra.prepfits';

addRequired(p,    'q',                          @(x)isnumeric(x)  );
addRequired(p,    'dqdt',                       @(x)isnumeric(x)  );
addParameter(p,   'weights',  ones(size(q)),    @(x)isnumeric(x)  );
addParameter(p,   'mask',     true(size(q)),    @(x)islogical(x)  );

parse(p,q,dqdt,varargin{:});

w = p.Results.weights;
m = p.Results.mask;
%-------------------------------------------------------------------------------

% keep the negative dq/dt values
keep = dqdt<0;
x = abs(q(keep));
y = abs(dqdt(keep));
w = w(keep);
m = m(keep);

% convert the mask to weights
w(m==false) = 0;

[x, y, w] = bfra.util.prepCurveData(x, y, w);
[logx, logy, w] = bfra.util.prepCurveData(log(x), log(y), w);

% failure check
ok = numel(y)>3;

