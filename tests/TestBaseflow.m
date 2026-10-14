classdef TestBaseflow < matlab.unittest.TestCase
   %TESTBASEFLOW Test the baseflow toolbox workflow.
   %
   % TestBaseflow is the integration suite for the documented workflow of
   % baseflow_demo_kuparuk and baseflow_demo_3. The class setup runs that
   % chain once on the Kuparuk record: wrapevents, fitevents, globalfit,
   % baseflowtrend at the expected-flow quantile, and aquiferthickness.
   % Each test checks one stage against the stages before it and against an
   % independent value or relationship:
   %     1) the event-detection defaults and rmax guard of getevents,
   %        eventfinder, and wrapevents
   %     2) the published Kuparuk recession exponent (Cooper et al., 2023)
   %     3) the tail, mean tau, and expected flows of globalfit
   %     4) the baseflow trend at the expected-flow quantile
   %     5) the aquifer thickness from that trend, and its uncertainty
   %     6) the BS04 and RS05 aquifer properties at b = 3/2, where the two
   %        solutions coincide
   %
   % A synthetic set of exact recessions, whose starting tau follows a
   % Pareto tail with alpha = 1.5, checks the event fits and the tau sample
   % against the known recession, and the divergent case, where the mean
   % tau and the expected flow do not exist.
   %
   % Notes:
   %     A) A negative test verifies that the code errors/fails in an
   %        expected way (e.g., the code gives the right error for a
   %        specific bad input)
   % 
   % See also: test_internal

   properties (TestParameter)
      SetupOption = {'install','uninstall','dependencies','addpath','savepath','rmpath','delpath'};
      EventFunction = {'getevents', 'eventfinder', 'wrapevents'};
   end

   properties (Constant)
      % Kuparuk basin area [m2], drainage density [1/km], and reference
      % aquifer thickness [m] of baseflow_demo_kuparuk.
      A = 8.6545e9
      Dd = 0.8
      D = 0.47

      % The recession exponent that Cooper et al. (2023) publish for the
      % Kuparuk annual workflow, and the rounding of the published value.
      publishedb = 1.3540
      btol = 5e-4

      % The synthetic recessions follow -dQ/dt = a*Q^b for eight days. The
      % starting tau of each event comes from a Pareto tail with pdf
      % exponent alpha and lower bound tau0 days.
      synth = struct('a', 1e-3, 'b', 1.5, 'alpha', 1.5, 'tau0', 5, ...
         'nevents', 60, 'ndays', 8)
   end

   properties (Access = private)
      % Open-figure snapshot taken before each test. The method teardown
      % closes only figures the test created, so a full suite run leaves
      % zero open figures without touching pre-existing user figures.
      figsbefore

      % Outputs of the Kuparuk chain, and the synthetic events, their
      % fits, and their true tau.
      Chain
      Synth
   end

   methods (TestClassSetup)
      function runkuparukchain(testCase)
         % Run baseflow_demo_kuparuk once, without figures or the bootstrap.
         % trendplot draws its figures off screen whatever showfig asks, so
         % close the figures the chain leaves.
         figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(figsbefore));
         L = testCase.A*testCase.Dd/1000;
         [T, Q, R] = baseflow.loadExampleData('kuparuk');
         opts = baseflow.setopts('globalfit', 'drainagearea', testCase.A, ...
            'aquiferdepth', testCase.D, 'streamlength', L, ...
            'drainagedensity', testCase.Dd, 'bootfit', false, ...
            'plotfits', false);
         Events = baseflow.wrapevents(T, Q, R, ...
            baseflow.setopts('getevents', 'asannual', true));
         [Fits, K] = baseflow.fitevents(Events, baseflow.setopts('fitevents'));
         GlobalFit = baseflow.globalfit(K, Events, Fits, opts);
         [Qb, dQbdt, Qa] = baseflow.baseflowtrend(T, Q, testCase.A, ...
            'pctl', GlobalFit.pQexp);
         [Db, Sb] = baseflow.aquiferthickness(GlobalFit.b, GlobalFit.tau, ...
            GlobalFit.phi, Qb, true);

         testCase.Chain = struct('T', T, 'Q', Q, 'Events', Events, ...
            'Fits', Fits, 'K', K, 'GlobalFit', GlobalFit, 'opts', opts, ...
            'Qb', Qb, 'dQbdt', dQbdt, 'Qa', Qa, 'Db', Db, 'Sb', Sb, 'L', L);
      end

      function buildsyntheticevents(testCase)
         % Exact recessions from Qnonlin, one per event, fit with the CTS
         % stencil. tau = Q^(1-b)/a grows by b-1 per day, so day t of an
         % event that starts at tau0 has tau = tau0 + (b-1)*t.
         s = testCase.synth;
         u = ((1:s.nevents)' - 0.5)/s.nevents;
         taustart = s.tau0*(1 - u).^(-1/(s.alpha - 1));
         tday = (0:s.ndays-1)';
         [t, Q, tags, tautrue] = deal(cell(s.nevents, 1));
         for k = 1:s.nevents
            Q0 = (s.a*taustart(k))^(1/(1-s.b));
            Q{k} = baseflow.Qnonlin(s.a, s.b, Q0, tday);
            t{k} = 20*(k-1) + tday;
            tags{k} = k*ones(s.ndays, 1);
            tautrue{k} = taustart(k) + (s.b-1)*tday;
         end
         Events = struct('eventTime', vertcat(t{:}), ...
            'eventFlow', vertcat(Q{:}), 'eventTags', vertcat(tags{:}));
         Events.eventRain = zeros(size(Events.eventFlow));
         Events.inputFlow = Events.eventFlow;
         [Fits, K] = baseflow.fitevents(Events, 'derivmethod', 'CTS');

         area = 1e9;
         opts = baseflow.setopts('globalfit', 'drainagearea', area, ...
            'aquiferdepth', 0.5, 'streamlength', area*testCase.Dd/1000, ...
            'drainagedensity', testCase.Dd, 'bootfit', false, ...
            'plotfits', false);
         testCase.Synth = struct('Events', Events, 'Fits', Fits, 'K', K, ...
            'opts', opts, 'tautrue', vertcat(tautrue{:}));
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_eventdefaults(testCase, EventFunction)

         % A call without options must use the setopts('getevents')
         % defaults. wrapevents needs complete calendar years, so all three
         % functions use the Kuparuk data. eventfinder rejects the setopts
         % fields that it does not parse, so remove them from its struct.
         [T, Q, R] = baseflow.loadExampleData('kuparuk');
         opts = baseflow.setopts('getevents');
         if strcmp(EventFunction, 'eventfinder')
            opts = rmfield(opts, {'qmin', 'cmax', 'pickevents', ...
               'plotevents', 'asannual'});
         end

         % Compare the first two outputs: events and Info, or event times
         % and flows for eventfinder
         eventfunction = str2func(['baseflow.' EventFunction]);
         expected = cell(1, 2);
         returned = cell(1, 2);
         [expected{:}] = eventfunction(T, Q, R, opts);
         [returned{:}] = eventfunction(T, Q, R);
         testCase.verifyEqual(returned, expected)
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_rmaxguard(testCase, EventFunction)

         % rmax must be greater than 1, because each nan counts as a run of
         % length 1 and rmnochange would reject every day. wrapevents
         % passes rmax to getevents, which raises the error.
         [T, Q, R] = baseflow.loadExampleData('kuparuk');
         eventfunction = str2func(['baseflow.' EventFunction]);
         validator = strrep(EventFunction, 'wrapevents', 'getevents');
         testCase.verifyError(@() eventfunction(T, Q, R, 'rmax', 1), ...
            ['MATLAB:' validator ':notGreater'])
      end

      function test_publishedRecessionExponent(testCase)
         % globalfit recovers the published Kuparuk recession exponent from
         % the tau sample of the event fits.
         returned = testCase.Chain.GlobalFit.b;

         testCase.verifyEqual(returned, testCase.publishedb, ...
            'AbsTol', testCase.btol)
      end

      function test_globalFitUsesTheTail(testCase)
         % The tail starts at the tau0 sample and holds no tau below it. The
         % mean tau follows tau0 and b, and the expected flows follow a, b,
         % and the mean tau. pQexp is the share of daily flows below Qexp.
         % a is positive and phi is a drainable porosity in (0, 1).
         G = testCase.Chain.GlobalFit;
         flow = testCase.Chain.Events.inputFlow;
         flow = flow(flow > 0);
         tol = 1e-12;

         testCase.verifyTrue(all(G.taumask(G.x == G.tau0)))
         testCase.verifyTrue(all(G.x(G.taumask) >= G.tau0))
         testCase.verifyEqual(G.tau, G.tau0*(2-G.b)/(3-2*G.b), 'RelTol', tol)
         testCase.verifyEqual(G.Qexp, (G.a*G.tau)^(1/(1-G.b)), 'RelTol', tol)
         testCase.verifyEqual(G.Q0, G.Qexp*(3-G.b)/(2-G.b), 'RelTol', tol)
         testCase.verifyEqual(G.pQexp, mean(flow < G.Qexp), ...
            'AbsTol', 2/numel(flow))
         testCase.verifyGreaterThan(G.a, 0)
         testCase.verifyGreaterThan(G.phi, 0)
         testCase.verifyLessThan(G.phi, 1)
      end

      function test_baseflowTrendAtExpectedFlowQuantile(testCase)
         % baseflowtrend fits the pQexp quantile of the annual flow. So, within
         % one year, at most pQexp of the years lie strictly below its line,
         % and at least pQexp lie on or below it.
         pQexp = testCase.Chain.GlobalFit.pQexp;
         Qa = testCase.Chain.Qa;
         trendline = testCase.Chain.dQbdt;
         slack = 1/numel(Qa);

         testCase.verifyLessThanOrEqual(mean(Qa < trendline), pQexp + slack)
         testCase.verifyGreaterThanOrEqual(mean(Qa <= trendline), ...
            pQexp - slack)
      end

      function test_thicknessFollowsBaseflow(testCase)
         % aquiferthickness scales the baseflow of each year by one factor
         % of tau, phi, and b, and the storage is phi times the thickness.
         G = testCase.Chain.GlobalFit;
         Db = testCase.Chain.Db;
         ratio = Db./testCase.Chain.Qb;
         tol = 1e-12;

         testCase.verifyEqual(ratio, ratio(1)*ones(size(ratio)), 'RelTol', tol)
         testCase.verifyEqual(testCase.Chain.Sb, G.phi*Db, 'RelTol', tol)
      end

      function test_uncertaintyCoverageFactor(testCase)
         % dndtuncertainty multiplies its combined standard uncertainty by
         % the coverage factor norminv(1-alpha/2). So the result for alpha
         % 0.32 is the result for alpha 0.05 times the ratio of the factors.
         % One seed gives both calls the same phi bootstrap. Qb is in cm/yr,
         % as baseflow_demo_kuparuk passes it. No figure stays open.
         C = testCase.Chain;
         alpha_default = 0.05;
         alpha_onesigma = 0.32;
         ratio_expected = norminv(1 - alpha_onesigma/2) ...
            / norminv(1 - alpha_default/2);
         tol = 0.01;
         rngstate = rng;
         testCase.addTeardown(@() rng(rngstate));

         rng(1)
         sig_default = baseflow.dndtuncertainty(C.T, C.Qb.*365.25, C.K, ...
            C.Fits, C.GlobalFit, C.opts, alpha_default);
         rng(1)
         sig_onesigma = baseflow.dndtuncertainty(C.T, C.Qb.*365.25, C.K, ...
            C.Fits, C.GlobalFit, C.opts, alpha_onesigma);

         testCase.verifyTrue(isfinite(sig_default))
         testCase.verifyEqual(sig_onesigma/sig_default, ratio_expected, ...
            'RelTol', tol)
         testCase.verifyEmpty(setdiff(findall(0, 'Type', 'figure'), ...
            testCase.figsbefore))
      end

      function test_aquiferPropsAgreeAtHomogeneousLimit(testCase)
         % At b = 3/2 the RS05 solution has n = 0, where it reduces to the
         % BS04 solution. So the two give the same k, D, and Q0. The BS04
         % constant 4.804 is published to three decimals. The inputs follow
         % baseflow_demo_3: the point cloud, its nls a, and phi = 0.033.
         q = testCase.Chain.Fits.q;
         dqdt = testCase.Chain.Fits.dqdt;
         Fit = baseflow.fitab(q, dqdt, 'nls');
         phi = 0.033;
         Dref = 0.5;
         tol = 1e-3;

         P_expected = baseflow.aquiferprops(q, dqdt, Fit.a, 1.5, 'BS04', ...
            phi, testCase.A, testCase.Chain.L);
         P_returned = baseflow.aquiferprops(q, dqdt, Fit.a, 1.5, 'RS05', ...
            phi, testCase.A, testCase.Chain.L, 'D', Dref);

         testCase.verifyEqual([P_returned.k P_returned.D P_returned.Q0], ...
            [P_expected.k P_expected.D P_expected.Q0], 'RelTol', tol)
      end

      function test_eventFitsRecoverTheRecession(testCase)
         % fitevents recovers the b of each exact recession, and eventtau
         % turns the event flows into the true tau of each day.
         S = testCase.Synth;
         b_expected = testCase.synth.b*ones(size([S.K.b]));
         tol = 1e-2;

         [tau_returned, ~, ~, tags_returned] = baseflow.eventtau(S.K, ...
            S.Events, S.Fits, 'usefits', false);

         testCase.verifyEqual([S.K.b], b_expected, 'RelTol', tol)
         testCase.verifyEqual(tags_returned, S.Events.eventTags)
         testCase.verifyEqual(tau_returned, S.tautrue, 'RelTol', tol)
      end

      function test_divergentTailHasNoExpectedFlow(testCase)
         % The tau sample has alpha near 1.5, beyond the tau pole at
         % alpha = 2, so the mean tau diverges. globalfit warns, the mean tau
         % is Inf, and the four expected-flow outputs are NaN. The baseflow
         % trend then has no quantile to fit, so it rejects pQexp. With
         % plotfits false, globalfit opens no figure.
         S = testCase.Synth;
         poleid = 'baseflow:expectedtau:tauPole';
         nan_expected = nan(1, 4);

         G = testCase.verifyWarning(@() baseflow.globalfit(S.K, S.Events, ...
            S.Fits, S.opts), poleid);

         testCase.verifyLessThanOrEqual(G.alpha, 2)
         testCase.verifyEqual(G.tau, Inf)
         testCase.verifyEqual([G.Qexp G.Q0 G.pQexp G.pQ0], nan_expected)
         testCase.verifyEmpty(setdiff(findall(0, 'Type', 'figure'), ...
            testCase.figsbefore))
         testCase.verifyError(@() baseflow.baseflowtrend(testCase.Chain.T, ...
            testCase.Chain.Q, testCase.A, 'pctl', G.pQexp), ...
            'MATLAB:InputParser:ArgumentFailedValidation')
      end
   end
end
