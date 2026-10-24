classdef test_flatcontract < matlab.unittest.TestCase
   %TEST_FLATCONTRACT Flat porosity values and early unsupported-call errors.
   properties (TestParameter)
      rejected = {'directFalse','cloudFalse','globalFalse','eventShort', ...
         'eventLong','cloudShort','cloudLong','directShort','directLong', ...
         'allPairs','directEmpty','cloudEmpty','directVector'}
      flatPair = {'linear','nonlinear'}
   end
   methods (TestMethodSetup)
      function preserveState(testCase)
         %PRESERVESTATE Restore random state and close test-created figures.
         rng_original = rng;
         testCase.addTeardown(@() rng(rng_original));
         figures_original = findall(groot,'Type','figure');
         testCase.addTeardown(@() closenewfigs(figures_original));
      end
   end
   methods (Test)
      function rejectsBeforeWork(testCase,rejected)
         %REJECTSBEFOREWORK Reject before RNG or figure changes.
         q = 2*ones(10,1); dqdt = -0.5*ones(10,1);
         rng(109); rng_expected = rng;
         figures_expected = findall(groot,'Type','figure');
         error_expected = 'baseflow:unsupportedSlopedAquifer';
         switch rejected
            case 'directFalse'
               call = @() baseflow.fitphi(1,1,1,100,2,10, ...
                  'isflat',false,'soln1','PK62','soln2','BS03');
            case 'directEmpty'
               call = @() baseflow.fitphi(1,1,1,100,2,10, ...
                  'isflat',logical([]),'soln1','PK62','soln2','BS03');
            case 'directVector'
               call = @() baseflow.fitphi(1,1,1,100,2,10, ...
                  'isflat',[true,true],'soln1','PK62','soln2','BS03');
            case 'cloudEmpty'
               call = @() baseflow.cloudphi(q,dqdt,1,100,2,10, ...
                  'envelope','isflat',logical([]),'plotfit',true);
            case 'cloudFalse'
               call = @() baseflow.cloudphi(q,dqdt,1,100,2,10, ...
                  'envelope','isflat',false,'plotfit',true);
            case 'globalFalse'
               % These parser-valid structs cannot reach eventtau safely.
               call = @() baseflow.globalfit(struct(), ...
                  struct('inputFlow',[]),struct(),'isflat',false, ...
                  'bootfit',true,'plotfits',true);
            case 'eventShort'
               call = @() baseflow.eventphi(struct(),struct(),100,2,10,1, ...
                  'soln1','BR94','soln2','BR94');
            case 'eventLong'
               call = @() baseflow.eventphi(struct(),struct(),100,2,10,1, ...
                  'soln1','Brutsaert, 1994', ...
                  'soln2','Rupp and Selker, 2006 b=1');
            case 'cloudShort'
               call = @() baseflow.cloudphi(q,dqdt,1,100,2,10, ...
                  'envelope','soln2','RS06b1','plotfit',true);
            case 'cloudLong'
               call = @() baseflow.cloudphi(q,dqdt,1,100,2,10, ...
                  'envelope','soln1','Brutsaert, 1994','plotfit',true);
            case 'directShort'
               call = @() baseflow.fitphi(1,1,1.5,100,2,10, ...
                  'soln1','BR94','soln2','RS06');
            case 'directLong'
               call = @() baseflow.fitphi(1,1,1.5,100,2,10, ...
                  'soln1','Brutsaert, 1994', ...
                  'soln2','Rupp and Selker, 2006 b=f(n)');
            case 'allPairs'
               call = @() baseflow.fitphi(1,1,1.5,100,2,10, ...
                  'soln1','all','soln2','all');
         end
         testCase.verifyError(call,error_expected);
         rng_returned = rng;
         figures_returned = findall(groot,'Type','figure');
         testCase.verifyEqual(rng_returned,rng_expected);
         testCase.verifyEqual(figures_returned,figures_expected);
      end
      function literalFlatSolutions(testCase,flatPair)
         %LITERALFLATSOLUTIONS Check flat values from forward coefficients.
         % Forward PK62/Boussinesq coefficients for k=1 and phi=0.1.
         phi_expected = 0.1;
         descriptionCount_expected = 2;
         tolerance = 2e-14;
         if strcmp(flatPair,'linear')
            a2 = 0.6579736267392905; b2 = 1; late = 'BS03';
         else
            a2 = 0.4804; b2 = 1.5; late = 'BS04';
         end
         [phi_returned,names_returned,description_returned] = ...
            baseflow.fitphi(0.0141625,a2,b2,100,2,10, ...
            'soln1','PK62','soln2',late);
         names_expected = {['PK62_' late]};
         testCase.verifyEqual(phi_returned,phi_expected,'AbsTol',tolerance);
         testCase.verifyEqual(names_returned,names_expected);
         testCase.verifyNumElements( ...
            description_returned,descriptionCount_expected);
      end
      function literalPublicRouting(testCase,flatPair)
         %LITERALPUBLICROUTING Check flat solutions through public callers.
         % Repeated points make every early/late quantile the same point.
         tolerance = 2e-14;
         if strcmp(flatPair,'linear')
            b2 = 1; phi_expected = 0.077226115743088686;
         else
            b2 = 1.5; phi_expected = 0.11872402921012785;
         end
         q = 2*ones(10,1); dqdt = -0.5*ones(10,1);
         cloud_returned = baseflow.cloudphi(q,dqdt,b2,100,2,10,'envelope', ...
            'plotfit',false);
         fits = struct('q',q,'dqdt',dqdt,'eventTags',ones(10,1));
         event_returned = baseflow.eventphi( ...
            struct('eventTag',1),fits,100,2,10,b2);
         testCase.verifyEqual(cloud_returned,phi_expected, ...
            'AbsTol',tolerance);
         testCase.verifyEqual(event_returned,phi_expected, ...
            'AbsTol',tolerance);
      end
   end
end
