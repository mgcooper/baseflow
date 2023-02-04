function [sig_dndt,sig_lamda] = dndtuncertainty(T,Qb,K,Fits,GlobalFit,opts,varargin)
%DNDTUNCERTAINTY compute combined uncertainty of the dn/dt trend estimate
%
% Syntax
% 
%     [sig_dndt,sig_lamda] = dndtuncertainty(T,Qb,K,Fits,GlobalFit,opts,varargin)
% 
% Description
% 
%     [sig_dndt,sig_lamda] = dndtuncertainty(T,Qb,K,Fits,GlobalFit,opts)
%     Computes the combined uncertainty (with correlation) for: dn/dt =
%     lambda*dq/dt where dn/dt is the 'long term' (interannual) trend in
%     groundwater layer thickness (n), q is the 'long term' trend in baseflow,
%     and lambda = tau/phi*1/(N+1) is the linearized sensitivity coefficient
%     with reference drainage timescale tau [days], drainable porosity [-], and
%     exponent N [-], where N=3-2b for all known flat-aquifer and all known
%     linearized sloped-aquifer solutions to the one-dimensional groundwater
%     flow equation for a Boussinesq aquifer, and parameter b from -dQ/dt = aQb.
%
% See also alttrend, aquiferthickness
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

% parse inputs
alpha = 0.05;
testflag = false;
if nargin == 7
   alpha = varargin{1};
elseif nargin == 8
   alpha = varargin{1};
   testflag = varargin{2};
end

% convert time in days to years
if ~isdatetime(T); T = datetime(T,'ConvertFrom','datenum'); end
[~,T] = padtimeseries(nan(size(T)),T,datenum(year(T(1)),1,1), ...
   datenum(year(T(end)),12,31),1);
T = transpose(year(mean(reshape(T,365,numel(T)/365))));

if numel(T) ~= numel(Qb)
   error('size T must match size Qb')
end

% define the sensitivity coefficient and dn/dt trend functions
Flam        = @(tau,phi,b) tau./(phi.*(4-2.*b)); 
Fdndt       = @(tau,phi,b,dqdt) tau./(phi.*(4-2.*b)).*dqdt;

% regress baseflow in units cm/day/year to get uncertainty on dq/dt 
% using fitlm on the baseflow timeseries:
% Qb          = GlobalFit.Qb./365.25;            % cm/yr -> cm/day
Qb          = Qb./365.25;            % cm/yr -> cm/day
mdl         = fitlm(T,Qb); % plot(mdl)
dbfdt       = mdl.Coefficients.Estimate(2);   % cm/day/year
std_dbfdt   = mdl.Coefficients.SE(2);         % standard error
CI_dbfdt    = mdl.coefCI;                     % 95% CI's
CI_dbfdt    = CI_dbfdt(2,:);
sig_dbfdt   = CI_dbfdt(2)-dbfdt;             % they're symetric so just take one

% parameters
A           = opts.drainagearea;     % basin area [m2]
D           = opts.aquiferdepth;     % reference active layer thickness [m]
L           = opts.streamlength;     % effective stream network length [m]
lateqtls    = opts.lateqtls;
earlyqtls   = opts.earlyqtls;
bhat        = GlobalFit.b;
PhiFit      = bfra.phifitensemble(K,Fits,A,D,L,bhat,lateqtls,earlyqtls,false);
% the sample populations of tau, phi, and Nstar

[~,~,~,~,G] = bfra.eventtau(K,Fits,Fits,'usefits',true,'aggfunc','max');
b           = [K.b]';
tau         = G.tau; % [K.tauH]';
Np1         = 1./(4-2.*b);
phi1        = PhiFit.phidist(:,1);
phi2        = PhiFit.phidist(:,2);
phi         = (phi1+phi2)./2;

% correlation between b and phi, using the two phi dist's b=1 and b=3/2:
rho_phi12   = nancorr(phi1,phi2);
rho_phib1   = nancorr(Np1,phi1);
rho_phib2   = nancorr(Np1,phi2);
cov_phib1   = cov(Np1,phi1,'omitrows');
cov_phib2   = cov(Np1,phi2,'omitrows');

% define the uncertainties (standard errors)
% if we averaged phi1 and phi2, then the combined uncertainty would be:
sig_phi1    = PhiFit.pm(1);
sig_phi2    = PhiFit.pm(2);
sig_phi12   = rho_phi12*sig_phi1*sig_phi2;
sig_phi     = sqrt((0.5*sig_phi1)^2+(0.5*sig_phi2)^2+2*0.5*0.5*sig_phi12);
sig_tau     = mean([GlobalFit.tau_H-GlobalFit.tau,GlobalFit.tau-GlobalFit.tau_L]);
sig_b       = mean([GlobalFit.b_H-GlobalFit.b,GlobalFit.b-GlobalFit.b_L]);
sig_Np1     = 2*sig_b;           % uncertainty on 1/(4-2*b) OR 1/(1-2*b) is 2*sig(b)
% the 0.5 on sig_phi1/2 is from the averaging procedure which divides by 2

if alpha == 0.32
   sig_phi     = sig_phi/2;
   sig_tau     = sig_tau/2;
   sig_b       = sig_b/2;
   sig_Np1     = sig_Np1/2;         % uncertainty on 1/(N+1) = 2*sig(b)
end


% mean values of parameters
tauhat      = GlobalFit.tau;                       % days
phihat      = PhiFit.mu(4);                        % -
bhat        = GlobalFit.b;                         % -
Nhat        = 1/(4-2*bhat);                        % -

% compute the sensitivity coefficient and dn/dt
lambda      = Flam(tauhat,phihat,bhat);
dndt        = Fdndt(tauhat,phihat,bhat,dbfdt);      % cm/yr

% compute the jacobian 
dqdtv       = dbfdt.*ones(size(tau));
J           = [dndt./tauhat, -dndt./phihat, dndt./Nhat, dndt./dbfdt];

% constrtuct the covariance matrix and compute the combined uncertainty
u           = [sig_tau, sig_phi, sig_Np1, sig_dbfdt];
V           = corr([tau,phi,Np1,dqdtv]).*u.*u';
sig_dndt    = sqrt(J*V*J');
% w/o correlated errors: sqrt(sum((J.*u).^2))

% compute the uncertainty on lambda (repeat above steps)
J           = [lambda./tauhat, -lambda./phihat, lambda./Nhat];
u           = [sig_tau, sig_phi, sig_Np1];
V           = corr([tau,phi,Np1]).*u.*u';
sig_lamda   = sqrt(J*V*J');
% w/o correlated errors: sqrt(sum((J.*u).^2))

%-------------------------------------------------------------------------------
% Methods comparison
%-------------------------------------------------------------------------------

if testflag == true
   warning('method comparison not currently supported')
end

% % Define symbols, setup matrices, etc.
% 
% % FsigX is the standard uncertainty formula for four variables: tau, phi, b,
% % dq/dt. 
% 
% % FsigX2 is for two variables: lambda and dq/dt, so it uses Flambda(X) within
% % the function to compute the value of lambda, but accepts the scalar values for
% % dq/dt (Fx2) and sig_dq/dt (sig_x2). It would be clearer to replace this with
% % the scalar valued version, because this is just used to combine the lambda
% % uncertainty from worstcase with the linear regression dq/dt uncertainty.
% 
% % Methods that use Fdndt require the same format that is used in the main
% % function, so it is not redefined here
% 
% sympref('FloatingPointOutput',true);
% syms tausym phisym bsym Qsym
% 
% % define vector valued functions
% FsigX    = @(X,Fx,sigX) Fx*sqrt((sigX(1)/X(1))^2+(sigX(2)/X(2))^2+ ...
%                         (sigX(3)/X(3))^2+(sigX(4)/X(4))^2);
% FsigX2   = @(X,Fx,Fx1,sig_x1,Fx2,sig_x2) Fx(X)*sqrt((sig_x1/Fx1(X))^2+ ...
%                         (sig_x2/Fx2)^2);
% FlamX    = @(X) X(1)./(X(2).*(4-2.*X(3)));            % lambda
% FdndtX   = @(X) X(1)./(X(2).*(4-2.*X(3))).*X(4);      % dn/dt
% Fsym     = tausym./(phisym.*(4-2.*bsym)).*Qsym;       % dn/dt
% % Flam     = tausym./(phisym.*(4-2.*bsym));             % lambda for f5
% Xsym     = [tausym phisym bsym Qsym];
% X        = [tauhat;phihat;bhat;dbfdt]; %[tau,phi,b];
% sigX     = [sig_tau;sig_phi;sig_b;sig_dbfdt];
% 
% % setup jacobian and covariance matrices (need the sample populations)
% dqdtv    = dbfdt.*ones(size(tau)); % dq/dt vector
% J        = [dndt./tauhat, dndt./phihat, dndt./Nhat, dndt./dbfdt]; % jacobian
% u        = [sig_tau, sig_phi, sig_Np1, sig_dbfdt]; % note: sig_Np1 not sig_b
% V        = corr([tau,phi,Np1,dqdtv]); % covariance matrix 
% corrX    = corr([tau,phi,Np1,dqdtv]);
% 
% % -----------------------------------------------------------------------------
% 
% casenames = {'inline w/o correlation','PropError w/o correlation', ...
%    'propUncertSym w/o correlation','worstcase w/o correlation',...
%    'inline w/correlation','propUncertSym w/ correlation', ...
%    'propUncertCD w/ correlation','worstcase w/correlation',...
%    'error propagation'};
%    
% % WITHOUT CORRELATION
% % -------------------
% 
% % METHOD 1: simple, uncorrelated errors (ends up close to PropError below)
% val(1)   = dndt;
% sig(1)   = FsigX(X,dndt,sigX); % also: sig = sqrt(sum((J.*u).^2))
% 
% % METHOD 2: PropError without correlated errors
% out      = PropError(Fsym,Xsym,X',sigX');
% val(2)   = out{1,1};
% sig(2)   = out{1,3};
% % out = PropError(Flam,Xsym(1:3),X(1:3)',sigX(1:3)'); % lambda
% 
% % METHOD 3: propUncert without correlated errors
% [sig(3),val(3)] = propUncertSym(Fsym,Xsym,X',sigX');
% 
% % METHOD 4: 'worstcase' without correlated errors
% [~,~,L,M,H] = worstcase(FlamX,X(1:3),sigX(1:3)); % lambda L/M/H
% sig_lam     = mean([H-M,M-L]);                     % lambda absolute uncertainty
% val(4)      = M*dbfdt;
% sig(4)      = FsigX2(X,FdndtX,FlamX,sig_lam,dbfdt,sig_dbfdt);
% 
% % for reference, compare what worstcase and sig_lam above do to expicit versions:
% % [sig(8)  dndt*sqrt((sig_lam/Flambda(X))^2 + (sig_dbfdt/dbfdt)^2)]
% % [sig_lam lambda*sqrt((sig_lam/Flambda(X))^2)]
% 
% % if the first two outputs of worstcase are returned, this shows what they mean:
% % [v1,v2,L,M,H] = worstcase(FlamX,X(1:3),sigX(1:3)); % lambda L/M/H
% % [Flambda(v1) L]
% % [Flambda(v2) H]
% 
% % WITH CORRELATION
% % ----------------
% 
% % METHOD 5: correlated errors (need the jacobian)
% val(5)   = dndt;
% sig(5)   = sqrt(J*(V.*u.*u')*J');
% 
% % METHOD 6: propUncert with correlated errors
% [sig(6),val(6)] = propUncertSym(Fsym,Xsym,X',sigX',corrX);
% 
% % METHOD 7: propUncertCD with correlated errors (central difference approx) 
% [sig(7),val(7)] = propUncertCD(FdndtX,X,sigX,corrX);
% 
% % METHOD 8: 'worstcase' with correlated errors
% [~,~,L,M,H] = worstcase(FdndtX,X,sigX);
% val(8)      = M;
% sig(8)      = mean([H-M,M-L]);      % absolute uncertainty
%             
% 
% % METHOD 9: error_propagation (documentation isn't clear and code style is
% % unfamiliar so i am not certain if correlation is included)
% [val(9),sig(9)] = error_propagation(Fdndt,tauhat,phihat,bhat,dbfdt,sig_tau,...
%    sig_phi,sig_b,sig_dbfdt);
% 
% 
% % SEE THE RESULTS
% %----------------------
% 
% % print the value returned by the main function:
% fprintf(['\nbfra:\nF(x) = %.2f ' char(177) ' %.3f (' num2str(1-alpha) ...
%    '%% CI) \n'],dndt,sig_dndt);
% 
% for n = 1:numel(casenames)
% 
%    fprintf(['\n' casenames{n} ':\n F(x) = %.2f ' char(177) ' %.3f (' ...
%       num2str(1-alpha) '%% CI) \n'],val(n),sig(n));
% end
% 
% end
% 
% % % this is the correlated errors case for lambda
% % J           = [dndt./tauhat, dndt./phihat, dndt./Nhat ];
% % u           = [sig_tau, sig_phi, sig_Np1];
% % V           = corr([tau,phi,Np1]);
% % sig_lam  = sqrt(J*(V.*u.*u')*J');         % this is the stdv of lambda
% % sigf2       = dndt*sqrt((sig_lam/lambda)^2 + (sig_dbfdt/dbfdt)^2) % 0.62 cm/yr
% 
% % this was after propUncertSym, in case the varnanmes matter. at this point i
% % think i noticed the correlation doesn't change the uncertainty by much so i
% % probably jus twanted to also show it doesn't change the uncertainty on lambda
% % by much 
% % % this shows that the correlation also doesn't change sig_lambda
% % Fsym        = tausym./(phisym.*(4-2.*bsym)); 
% % Xsym        = [tausym phisym bsym];
% % X           = [tauhat phihat bhat]; %[tau,phi,b];
% % sigX        = [sig_tau sig_phi sig_b];
% % corrX       = corr([tau,phi,Np1]);
% % % sig_lambda  = PropError(Fsym,Xsym,X,sigX)
% % % sig_lambda  = propUncertSym(Fsym,Xsym,X,sigX)
% % % sig_lambda  = propUncertSym(Fsym,Xsym,X,sigX,corrX)
