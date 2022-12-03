function [ab,yfit,xfit] = olsfit(x,y,varargin)
%OLSFIT fit ordinary least squares linear regressioin

% NOTE: output is YFIT then XFIT,

% option to fit log models
if nargin == 2
   logopt = 'linear';
else
   logopt   = varargin{1};
end

% although prepareCurveData will do this, it issues an error which can
% be annoying and/or confusing
x  = x(:);
y  = y(:);  % only single linear regression is supported


% assume nan values in y should dictate removal of x,y values
[y,naninds] = rmnan(y);
x(naninds)  = [];

[x,y] = prepareCurveData(x,y);
xfit = linspace(0.98*min(x),1.02.*max(x),100);

switch logopt
   case 'semilogy'
      y = log(y);
   case 'semilogx'
      x = log(x);
   case 'loglog'
      y = log(y);
      x = log(x);
end

if isempty(x) || isempty(y)
   ab = [nan; nan]; yfit = nan(size(y)); xfit = nan(size(x));
   return;
end

N = numel(x);
ab = [ones(N,1),x]\y;

% the log functions assume models of the form:
% log(y) = log(a) + b*log(x)     ->    y     = a*x^b
% log(y) = log(a) + b*x          ->    y     = a*e^(b*x)
% y      = a      + b*log(x)     ->    e^y   = a*x^b

switch logopt
   
   case 'semilogy'
      
      % if we first transform a:
      ab(1) = exp(ab(1));
      yfit  = ab(1).*exp(ab(2).*xfit);
      
      % if we don't:
      % yfit  = exp(ab(1) + ab(2).*xfit);
      
      % if we leave the fit in semilog space (yfit is log(yhat)):
      % yfit = ab(1) + ab(2).*xfit;
      
   case 'semilogx'
      
      % NOTE: this one is a bit confusing. it all depends how you want
      % the coefficients returned.
      
      % if we first transform a:
      ab(1) = exp(ab(1));
      yfit  = log(ab(1).*xfit.^b);
      
      % if we don't:
      % yfit  = ab(1) + ab(2).*log(xfit);
      % ab(1) = exp(ab(1));
      
      % in the second case, ab(1) is a in: e^y = a*x^b
      
      % if we leave the fit in log-log space (xfit is log(xhat)):
      % yfit = ab(1) + ab(2).*log(xfit);
      
   case 'loglog'
      
%       % before transforming a back:
%       figure; plot(x,y,'o'); hold on; % note: x,y are logged
%       plot(log(xfit),ab(1)+ab(2).*log(xfit))
      
      % if we first transform a:
      ab(1) = exp(ab(1));
      yfit  = ab(1).*xfit.^ab(2);
      
%       % after transforming a back:
%       figure; plot(x,y,'o'); hold on;
%       plot(log(xfit),log(yfit));
%       
%       figure; loglog(exp(x),exp(y),'o'); hold on;
%       plot(xfit,yfit);
%       
%       figure; plot(exp(x),exp(y),'o'); hold on;
%       plot(xfit,yfit);
      
      % if we don't:
      % yfit = exp(ab(1) + ab(2).*log(xfit));
      
      % if we leave the fit in log-log space (yfit is log(yhat)):
      % yfit = ab(1) + ab(2).*log(xfit);
      
end

ab = ab';

% clarifying the governing forms of the semilog models:

% if the model is y = e^(a + bx)
% then log(y) = a + b*x

% if the model is y = a*e^(b*x)
% then log(y) = log(a) + b*x