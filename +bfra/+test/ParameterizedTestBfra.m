classdef ParameterizedTestBfra < matlab.unittest.TestCase

   properties (TestParameter)
      VarStr = {'Q','dQdt','aQb'};
      DerivMethod = {'CTS'}; % {'ETS','VTS','CTS'}
      FitMethod = {'ols','nls','mean','median'};
      ModelExponent = {1.0,1.5}; % linear and non-linear
   end

   methods (Test)

      function testString(testCase,VarStr)

      switch VarStr
         case 'Q'
            expectedStr = '$Q$';
         case 'dQdt'
            expectedStr = '$-\mathrm{d}Q/\mathrm{d}t$';
         case 'aQb'
            expectedStr = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';
      end

      % Get actual result
      strActual = bfra.getstring(VarStr);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual(strActual,expectedStr)
      end
   
      %-------------------------------------------
      %-------------------------------------------
      function testBfraDqdt(testCase,DerivMethod)

      % define the test data
      a = 1e-2;
      b = 1.5;
      q0 = 1;
      [q,~,t] = bfra.generateTestData(a,b,q0);

      % Calculate expected result for CTS method
      dq = q-[nan; q(1:end-1)];
      dt = (t(2)-t(1));
      dqdtExpected = dq./dt;

      % Get the actual result
      [~,dqdtActual] = bfra.getdqdt(t,q,[],DerivMethod);
         
      % Verify that the actual result matches the expected result
      testCase.verifyEqual(dqdtActual,dqdtExpected)

      % for testing:
      % DerivMethod = 'CTS';
      % [~,dqdtActual] = bfra.getdqdt(t,q,[],DerivMethod);
      % isequal(dqdtActual,dqdtExpected)
      % scatterfit(dqdtActual,dqdtExpected)

      end

      %-------------------------------------------
      %-------------------------------------------
      function testBfraFitab(testCase,ModelExponent,FitMethod)
      
      % define values to generate the test data
      a = 1e-2;
      q0 = 100;
      t = 1:100;
      b = ModelExponent;

      % for testing
      % FitMethod = 'ols';
      % b = 1.5;
      % [q,dqdt] = bfra.generateTestData(a,b,q0,t);
      % figure; loglog(q,-dqdt,'o')
      % also useful to see this:
      % bfra.Qnonlin(a,b,q0,t,true) 
      
      % f = bfra.fitab(q,dqdt,'mean'); ab = f.ab
      % f = bfra.fitab(q,dqdt,'ols'); ab = f.ab
      % f = bfra.fitab(q,dqdt,'nls'); ab = f.ab
      % f = bfra.fitab(q,dqdt,'median'); ab = f.ab

      % generate the test data
      [q,dqdt] = bfra.generateTestData(a,b,q0,t);

      % fit the data
      switch FitMethod
         case {'mean','median'}
            Fit = bfra.fitab(q,dqdt,FitMethod,'order',b);
         otherwise
            Fit = bfra.fitab(q,dqdt,FitMethod);
      end
      
      % Get the expected result
      abExpected = [a;b];

      % Get the actual result
      abActual = Fit.ab;

      % for testing:
      % f = bfra.fitab(q,dqdt,FitMethod); abActual = f.ab
      % isequal(abActual,abExpected)
         
      % Verify that the actual result matches the expected result
      testCase.verifyEqual(abActual,abExpected,'RelTol',[0.01; 0.01])

      end
   end
end

