function PhiFit = phifitensemble(K,Fits,A,D,L,bhat,lateqtls,earlyqtls,showfit)

% phid  = bfra.eventphi(K,Fits,A,D,[],bhat);
% phi   = bfra.fitphidist(phid,'mean','cdf');
phidist(:,1)   = bfra.eventphi(K,Fits,A,D,L,1,'lateqtls',lateqtls,'earlyqtls',earlyqtls);
phidist(:,2)   = bfra.eventphi(K,Fits,A,D,L,1.5,'lateqtls',lateqtls,'earlyqtls',earlyqtls);
phidist(:,3)   = bfra.eventphi(K,Fits,A,D,L,bhat,'lateqtls',lateqtls,'earlyqtls',earlyqtls);

% 
phidist(phidist>1.0) = nan;
phidist(phidist<0.0) = nan;
phicombo       = vertcat(phidist(:,1),phidist(:,2));

% plot the fits
[PD(1),h1]  = bfra.fitphidist(phidist(:,1),'PD','cdf',showfit); 
[PD(2),h2]  = bfra.fitphidist(phidist(:,2),'PD','cdf',showfit); 
[PD(3),h3]  = bfra.fitphidist(phidist(:,3),'PD','cdf',showfit); 
[PD(4),h4]  = bfra.fitphidist(phicombo,'PD','cdf',showfit); 

% put the mean and standard errors in an array
mu          = [h1.mu; h2.mu; h3.mu; h4.mu];
pm          = [h1.pm; h2.pm; h3.pm; h4.pm];


PhiFit.phidist = phidist;
PhiFit.phi12   = phicombo;
PhiFit.PD      = PD;
PhiFit.mu      = mu;
PhiFit.pm      = pm;


% [F1,h1]  = bfra.fitphidist(phi1,'PD','cdf');
% [F2,h2]  = bfra.fitphidist(phi2,'PD','cdf');
% [F3,h3]  = bfra.fitphidist(phi3,'PD','cdf');
% [F4,h4]  = bfra.fitphidist(phi4,'PD','cdf');
% [F,h]    = bfra.fitphidist([phi1;phi2],'PD','cdf');
