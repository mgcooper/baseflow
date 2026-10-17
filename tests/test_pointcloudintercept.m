classdef test_pointcloudintercept < matlab.unittest.TestCase
   %TEST_POINTCLOUDINTERCEPT Test the intercept bounds of pointcloudintercept.
   %
   % The bounds pivot the line through the reference point (xbar, ybar)
   % with the slopes in bci, so a(b) = ybar/xbar^b. a is monotonic in b at
   % a fixed pivot, so the bounds bracket ahat for every method. A flow
   % below 1 makes log(xbar) negative, which reverses which slope bound
   % gives the lower a.

   properties (TestParameter)
      % Methods with a reference point in flow units.
      method = {'mean', 'median', 'envelope'}

      % Flow scales that put the reference flow above and below 1.
      flowscale = struct('above1', 1, 'below1', 1e-4)
   end

   methods (Test)
      function test_boundsBracketTheIntercept(testCase, method, flowscale)
         % The lower bound is at most ahat, and the upper bound at least.
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~,q,dqdt] = baseflow.generateTestData(a,b,q0,t);
         bci = b + [-0.1 0.1];

         [ahat, ahatLH] = baseflow.pointcloudintercept(flowscale*q, ...
            flowscale*dqdt, b, method, 'bci', bci);

         testCase.verifyLessThanOrEqual(ahatLH(1), ahat)
         testCase.verifyGreaterThanOrEqual(ahatLH(2), ahat)
      end
   end
end
