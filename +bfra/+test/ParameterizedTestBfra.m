classdef ParameterizedTestBfra < matlab.unittest.TestCase

   properties (TestParameter)
      SetupOption = {'install','uninstall','dependencies','addpath','savepath','rmpath','delpath'};
      VarStr = {'Q','dQdt','aQb'};
      DerivMethod = {'CTS'}; % {'ETS','VTS','CTS'}
      FitMethod = {'ols','nls','mean','median'};
      RecessionExponent = {1.0,1.5}; % linear and non-linear
      RecessionParameterNames = {'b','n','alpha'};
      PowerLawExponent = {1.5, 2.0, 2.5, 3.0, 3.5};
      TauValue = {10, 100, 1000};
      PhiValue = {0.001, 0.01, 0.1};
      BasinName = {'ALL_BASINS','KUPARUK R NR DEADHORSE AK'};
      MinEventDuration = {3,6,9};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      % function test_setup(testCase,SetupOption)
      %    
      % end

      %-------------------------------------------
      %-------------------------------------------
      function test_getstring(testCase,VarStr)

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
      function test_getdqdt(testCase,DerivMethod)

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
      function test_fitab(testCase,RecessionExponent,FitMethod)
      
      % define values to generate the test data
      a = 1e-2;
      q0 = 100;
      t = 1:100;
      b = RecessionExponent;

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

      %-------------------------------------------
      %-------------------------------------------
      function test_conversions(testCase,RecessionParameterNames)

      switch RecessionParameterNames
         case 'b'
            b = 1.5;
            nExpected = 0;
            nActual = bfra.conversions(b,'b','n','isflat',true);
            
            % Verify that the actual result matches the expected result
            testCase.verifyEqual(nActual,nExpected);

         case 'n'
            n = -1;
            bExpected = 1;
            bActual = bfra.conversions(n,'n','b','isflat',true);

            % Verify that the actual result matches the expected result
            testCase.verifyEqual(bActual,bExpected);

         case 'alpha'
            alpha = 4.0;
            bExpected = 1.25;
            bActual = bfra.conversions(alpha,'alpha','b','isflat',true);

            % Verify that the actual result matches the expected result
            testCase.verifyEqual(bActual,bExpected);
      end

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_plfitb(testCase,PowerLawExponent)

      % generate power-law distributed test data
      x = (1-rand(10000,1)).^(-1/(PowerLawExponent-1));

      % compute the fit
      [bActual,alphaActual] = bfra.plfitb(x);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual(PowerLawExponent,alphaActual,'AbsTol',0.1);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_aquiferstorage(testCase,RecessionExponent)

      % make test data
      qmin = 1;
      qmax = 100;
      a = 1;
      b = RecessionExponent;

      % compute the expected result
      switch RecessionExponent
         case 1.0
            SminExpected = 1/a*qmin;
            SmaxExpected = 1/a*qmax;

         case 1.5
            SminExpected = 1/a/(2-b).*(qmin.^(2-b));
            SmaxExpected = 1/a/(2-b).*(qmax.^(2-b));
      end
      
      % get the actual result
      [SminActual,SmaxActual] = bfra.aquiferstorage(a,b,qmin,qmax);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual([SminExpected,SmaxExpected],[SminActual,SmaxActual]);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_aquiferthickness(testCase,RecessionExponent,TauValue,PhiValue)

      % note: this implicitly tests bfra.conversions

      % make test data
      Qb = 2;
      b = RecessionExponent;
      tau = TauValue;
      phi = PhiValue;

      % compute the expected result
      DExpected = tau/phi/(4-2*b)*Qb;
      SExpected = DExpected*phi;
      
      % get the actual result
      [DActual,SActual] = bfra.aquiferthickness(b,tau,phi,Qb);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual([DExpected,SExpected],[DActual,SActual]);

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_eventfinder(testCase,MinEventDuration)
      
      nmin = MinEventDuration;

      % this should work in general, as long as prec is used consistently
      prec = 3; % precision, controls how large the test vectors are
      dpi = 10^-prec;

      % generate synthetic data
      t = -2*pi:dpi:2*pi;
      q = 1 + sin(t);

      % find the maxima and minima (where d/dt sin(t) == 0)
      idx = find(abs(round(cos(t),prec))==0);
      idx = transpose(reshape(idx,2,[])); % [istart istop]

      for n = 1:numel(idx)/2
         ievent = idx(n,1)+2 : idx(n,2)-1;
         tExpected{n,1} = transpose(t(ievent));
         qExpected{n,1} = transpose(q(ievent));
      end

      % get the actual result
      [tActual,qActual] = bfra.eventfinder(t,q,[],'nmin',nmin,'fmax',0, ...
         'rmax',0,'rmin',0,'rmconvex',false,'rmnochange',false,'rmrain',false);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual([tExpected,qExpected],[tActual,qActual]);

      % for debugging
      % --------------
      % convert to start/stop indices. remove the peak + 1 day, and the min.
      % ievent1 = idx(1,1)+2 : idx(1,2)-1;
      % ievent2 = idx(2,1)+2 : idx(2,2)-1;

      % tExpected{n} = transpose(t(ievent1));
      % qExpected{n} = transpose(q(ievent1));
      % tExpected{2} = transpose(t(ievent2));
      % qExpected{2} = transpose(q(ievent2));

      % isequal(tExpected{1},tActual{1})
      % isequal(tExpected{2},tActual{2})

      % figure; plot(t,q); hold on; 
      % plot(tExpected{1},qExpected{1});
      % plot(tExpected{2},qExpected{2});
      % plot(tActual{1},qActual{1},':');
      % plot(tActual{2},qActual{2},':');

%       % minima should be at -pi/2, 3*pi/2
%       % maxima should be at pi/2, -3*pi/2
%       s1 = find(t+3*pi/2>0,1,'first')-1;
%       e1 = find(t+pi/2>0,1,'first')-1;
%       s2 = find(t-pi/2>0,1,'first')-1;
%       e2 = find(t-3*pi/2>0,1,'first')-1;
% 
%       % remove the peak + 1 day, and the min
%       s1 = s1+2; s2 = s2+2;
%       e1 = e1-1; e2 = e2-1;

      end

      %-------------------------------------------
      %-------------------------------------------
      function test_basinname(testCase,BasinName)

      % get the basin name from the database
      ActualName = bfra.basinname(BasinName);

      % Verify that the actual result matches the expected result
      testCase.verifyEqual(BasinName,ActualName);

      end

   end
end

