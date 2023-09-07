function GlobalFit = globalfit(Results,Events,Fits,varargin)
   %GLOBALFIT Fit global parameters using all event-scale recession fits.
   %
   % Syntax
   %
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits);
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits,opts);
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits,Meta,'plotfits',plotfits);
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits,Meta,'bootfit',bootfit);
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits,Meta,'bootfit',bootfit,'bootreps',nreps);
   %     FIT = bfra.GLOBALFIT(___,)
   %
   % Description
   %
   %     FIT = bfra.GLOBALFIT(Results,Events,Fits) uses the event-scale recession
   %     analysis parameters saved in results table Results and fitted data saved
   %     in Fits (both outputs of bfra.fitevents) and the event-scale data saved in
   %     Events (output of bfra.getevents) and computes 'global' parameters tau,
   %     tau0, phi, bhat, ahat, Qexp, and Q0.
   %
   % Required inputs
   %
   %     Results, Events, Fits are outputs of bfra.getevents and bfra.fitevents
   %     opts is a struct containing fields area, D0, and L (see below)
   %
   % See also: setopts, getevents, fitevents, fitphi, eventphi, eventtau
   %
   % Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % TODO make the inputs more general, rather than these hard-coded structures
   % and tables

   % NOTE in the current setup, early/lateqtls are used for eventphi, refqtls for
   % point cloud

   % PARSE INPUTS
   %#ok<*ASGLU>
   [Q, A, Dd, D, L, theta, B, phi, plotfits, bootfit, nreps, phimethod, ...
      refqtls, earlyqtls, lateqtls, isflat] = parseinputs( ...
      Results, Events, Fits, mfilename, varargin{:});

   % Fit tau, a, b (tau [days], q [m3 d-1], dqdt [m3 d-2])
   [tau, q, dqdt, tags] = bfra.eventtau(Results, Events, Fits, 'usefits', false);
   
   TauFit = bfra.plfitb(tau, 'plotfit', plotfits, 'bootfit', bootfit, ...
      'bootreps', nreps, 'limit', 20);

   % Parameters needed for next steps
   bhat     = TauFit.b;
   bhatL    = TauFit.b_L;
   bhatH    = TauFit.b_H;
   tau0     = TauFit.tau0;
   tauexp   = TauFit.tau;
   itau     = TauFit.taumask;

   % Fit a
   [ahat, ahatLH, xbar, ybar] = bfra.pointcloudintercept(q, dqdt, bhat, ...
      'envelope', 'refqtls', refqtls, 'mask', itau, 'bci', [bhatL bhatH]);

   % Fit Q0 and Qhat
   [Qexp, Q0, pQexp, pQ0] = bfra.expectedQ(ahat, bhat, tauexp, q, dqdt, tau0, ...
      'qtls', Q, 'mask', itau);

   % Fit phi
   switch phimethod
      case 'distfit'
         phid = bfra.eventphi(Results, Fits, A, D, L, bhat, ...
            'lateqtls', lateqtls, 'earlyqtls', earlyqtls);
         phi = bfra.fitphidist(phid, 'mean', 'cdf', plotfits);

      case 'pointcloud'
         phi = bfra.cloudphi(q, dqdt, bhat, A, D, L, 'envelope', ...
            'lateqtls', refqtls, 'earlyqtls', earlyqtls, 'mask', itau);

      case 'phicombo'
         phi1 = bfra.eventphi(Results, Fits, A, D, L, 1, ...
            'lateqtls', lateqtls, 'earlyqtls', earlyqtls);
         phi2 = bfra.eventphi(Results, Fits, A, D, L, 3/2, ...
            'lateqtls', lateqtls, 'earlyqtls', earlyqtls);
         phid = vertcat(phi1, phi2); phid(phid>1) = nan; phid(phid<0) = nan;
         phi = bfra.fitphidist(phid, 'mean', 'cdf', plotfits);
   end

   % % Fit k
   % [k,Q0_2,D_2] = bfra.aquiferprops(q,dqdt,ahat,bhat,'RS05',phi,A,D,L, ...
   %    'mask',itau,'lateqtls',refqtls,'earlyqtls',earlyqtls,'Q0',Q0,'Dd',Dd);
   % Q0    = Qexp*(3-b)/(2-b);

   % note on units: ahat is estimated from the point cloud. the dimensions of ahat
   % are T^b-2 L^1-b. The time is in days and length is m3, so ahat has units
   % d^b-2 m^3(1-b) (it's easier if you pretend flow is m d-1). For Q0, we get:
   % (d^b-2 m^3(1-b) * d)^(1/1-b) = d^(b-1)/(1-b) m^3(1-b)/(1-b) = m^3 d-1

   % % turned this off b/c phicloud makes one
   % % plot the pointcloud if requested
   % if plotfits == true
   %
   %    h = bfra.pointcloudplot(q,dqdt,'blate',1,'mask',itau,    ...
   %    'reflines',{'early','late','userfit'},'reflabels',true, ...
   %    'userab',[ahat bhat],'addlegend',true);
   %    h.legend.AutoUpdate = 'off';
   %    scatter(xbar,ybar,60,'k','filled','s');
   % end

   % PARSE OUTPUTS
   GlobalFit      = TauFit;
   GlobalFit.phi  = phi;
   GlobalFit.q    = q;
   GlobalFit.dqdt = dqdt;
   GlobalFit.tags = tags;
   GlobalFit.a    = ahat;
   GlobalFit.a_L  = ahatLH(1);
   GlobalFit.a_H  = ahatLH(2);
   GlobalFit.xbar = xbar;
   GlobalFit.ybar = ybar;
   GlobalFit.Q0   = Q0;
   GlobalFit.Qexp = Qexp;
   GlobalFit.pQexp = pQexp;
   GlobalFit.pQ0  = pQ0;
end

%% INPUT PARSER
function [Q, A, Dd, D, L, theta, B, phi, plotfits, bootfit, bootreps, phimethod, ...
      refqtls, earlyqtls, lateqtls, isflat] = parseinputs(K, Events, Fits, ...
      funcname, varargin)

   parser = inputParser;
   parser.FunctionName = ['bfra.' funcname];
   parser.StructExpand = true;
   parser.PartialMatching = false;

   parser.addRequired('Results', @isstruct);
   parser.addRequired('Events', @isstruct);
   parser.addRequired('Fits', @isstruct);
   parser.addParameter('drainagearea', nan, @isnumericscalar);
   parser.addParameter('drainagedensity', 0.8, @isnumericscalar);
   parser.addParameter('aquiferdepth', nan, @isnumericscalar);
   parser.addParameter('streamlength', nan, @isnumericscalar);
   parser.addParameter('aquiferslope', nan, @isnumericscalar);
   parser.addParameter('aquiferbreadth', nan, @isnumericscalar);
   parser.addParameter('drainableporosity', 0.1, @isnumericscalar);
   parser.addParameter('isflat', true, @islogicalscalar);
   parser.addParameter('plotfits', false, @islogicalscalar);
   parser.addParameter('bootfit', false, @islogicalscalar);
   parser.addParameter('bootreps', 1000, @isdoublescalar);
   parser.addParameter('phimethod', 'pointcloud', @ischarlike);
   parser.addParameter('refqtls', [0.50 0.50],  @isnumericvector);
   parser.addParameter('earlyqtls', [0.95 0.95],  @isnumericvector);
   parser.addParameter('lateqtls', [0.50 0.50],  @isnumericvector);

   parser.parse(K, Events, Fits, varargin{:});

   A           = parser.Results.drainagearea;      % basin area [m2]
   Dd          = parser.Results.drainagedensity;   % drainage density [km-1]
   D           = parser.Results.aquiferdepth;      % reference active layer thickness [m]
   L           = parser.Results.streamlength;      % effective stream network length [m]
   theta       = parser.Results.aquiferslope;      % aquifer slope [1]
   B           = parser.Results.aquiferbreadth;    % aquifer breadth [m]
   phi         = parser.Results.drainableporosity; % drainable porosity [1]
   plotfits    = parser.Results.plotfits;
   bootfit     = parser.Results.bootfit;
   bootreps    = parser.Results.bootreps;
   phimethod   = parser.Results.phimethod;
   refqtls     = parser.Results.refqtls;
   earlyqtls   = parser.Results.earlyqtls;
   lateqtls    = parser.Results.lateqtls;
   isflat      = parser.Results.isflat;

   % if stream length and drainage density are both provided, check that they are
   % consistent with the provided area. note: Dd comes in as 1/km b/c that's how it
   % is almost always reported (km/km2). divide by 1000 to get 1/m.
   if ~isnan(Dd) && ~isnan(L)
      if Dd/1000*A ~= L        % 1/m * m^2 = m
         warning('provided streamlength, L, inconsistent with L=A*Dd. Using L=A*Dd');
         L = Dd/1000*A;
      end
   end

   % take values out of the data structures that are needed
   Q = Events.inputFlow;       % daily streamflow [m3 d-1]
end