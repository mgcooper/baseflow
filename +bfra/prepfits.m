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

% PARSE INPUTS
[q, dqdt, w, m] = parseinputs(q, dqdt, varargin{:});

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

%% parse inputs
function [q, dqdt, weights, mask] = parseinputs(q, dqdt, varargin)
parser = inputParser;
parser.FunctionName = 'bfra.prepfits';

parser.addRequired('q', @isnumeric);
parser.addRequired('dqdt', @isnumeric);
parser.addParameter('weights', ones(size(q)), @isnumeric);
parser.addParameter('mask', true(size(q)), @islogical);

parser.parse(q, dqdt, varargin{:});

weights = parser.Results.weights;
mask = parser.Results.mask;
