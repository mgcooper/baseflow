function [q,dqdt,t] = generateTestData(a,b,q0,t)
%GENERATETESTDATA generate test data for baseflow recession analysis
% 
% Syntax
% 
%     [q,dqdt,t] = generateTestData(a,b,q0,t)
% 
% Description
% 
%     [q,dqdt,t] = bfra.generateTestData(a,b,Q0,t) generates timeseries of
%     discharge Q, first derivative of discharge dQdt, and time t for parameter
%     values a,b, and initial discharge Q0
% 
% See also bfra.Qnonlin
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% default Q0 and time
switch nargin
   case 0
      a = 1e-2;
      b = 1.5;
      q0 = 100;
      t = 1:100;
   case 1 % assume b is provided, and swap a for b
      b = a;
      a = 1e-2;
      q0 = 100;
      t = 1:100;
   case 2
      q0 = 100;
      t = 1:100;
   case 3
      t = 1:100;
end

t = t(:);

switch b
   case 1
      q = q0.*exp(-a.*t);
      dqdt = -a.*q;
      %q = (q(1:end)+q(2:end-1))./2;
      %dqdt = diff(q);
   otherwise
      [q,dqdt,t] = bfra.Qnonlin(a,b,q0,t,false); % false = don't make fig
end


% % this was in bfra.test suite ParameterizedTestBfra. I am not certain why the
% data falls off, could be the noise I add, or could be the lack of a negative
% sign on in genCurveData
% for a linear model (exponential), Q = Q0*exp(-at), meaning 
% 
% for the linear case:
% data = genCurveData('exponential');
% a = 1e-2;
% q = data.y;
% dqdt = -a.*q;
% figure; semilogy(-dqdt,q,'o')
% 
% 
% for the nonlinear case:
% data = genCurveData('power');
% q = data.y;
% dqdt = -data.x;
% figure; loglog(-dqdt,q,'o')
% [x,y,logx,logy] = bfra.prepfits(q,dqdt);
% Fit = bfra.fitab(logx,logy,'nls');
