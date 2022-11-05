
function [Q0,k,D] = bfra_aquiferprops_test(q,dqdt,ahat,bhat,phi,itau,A,D,L,Qexp,Q0_ref)

% the steps / theory are:
% 1. Equation 8 provides late time q expression (hillslope outflow)
%     q = 0.862 * k * D^2 / (B * (1 + 1.115*k*D/(f*B^2)*t )^2)
% 
% 2. Equation 9 provides late time average water table thickness - obtained by
% integrating the inverse incomplete beta function phi(x/B) from 0->B = 0.773
%     hbar = 0.773 * D / (1 + 1.115*k*D/(f*B^2)*t ) 
% 
% 3. Sub 9 into 8 to get an expression for q in terms of hbar rather than D
% (note that hbar changes wrt time so q varies with time)
%     q = 1.443 * k/B * hbar^2
% 
% 4. integrate 10 to get basin outflow, sub Dd for L/A
%     Q = 5.772*k*hbar^2*Dd*L
% 
% 5. repeat step 4 for early time, by setting t=0 in Eq 8 (step 1) 
%     Q0 = 3.450 * k * D^2 * Dd * L
% 
% 6. set a1*Q^b1 = a2*Q^b2 and solve for Q - the intersection of the early- and
% late-time -dQ/dt lines on the point cloud
% 
% 7. estimate a1/b1 (late time) and a2/b2 (early time) on the point cloud
%
% 8. estimate Q0 from the intersection of early-and late-time curves (formal
% equation not shown, but should be: Q = (a1/a2)^(1/(b2-b1)) = (a2/a1)^(1/(b1-b2))
%
% 9. estimate k from equation 15a (late-time a1) using known L/A/f (f=porosity)
% NOTE: paper says use equation 16a (early-time a2) and 13, but clearly 13 is
% supposed to be 12, and since 16a includes D which is supposed to be solved for
% in the next step, i am nearly certain 15a should be used (both equations step
% back one)
% 
% 10. estimate D from k and known A/L/Dd using equation 12 (step 5)

%  Important notes
% -----------------
% Troch found k was 25-100 times larger than laboratory measurements and argued
% that this k is a catchment effective value which includes macropore flow,
% channel flow, etc.
% 
% This method needs a late-time solution that does not depend on aquifer depth
% in order to get k without assuming D, so that k can be used with Q0 to get D.
% if a late-time solution that depends on D is used, then you can still get k,
% but you cannot get D

% changing L changes k but does not change D b/c it cancels
% increasing a32 will increase k and decrease D 
% decreasing a32 will decrease k and increase D
% changing a3 will not change k but will change Q0 and therefore D
% increasing a3 will decrease Q0 and decrease D
% decreasing a3 will increase Q0 and increase D
% changing any value of a/b will change Q0 and therefore D

% takeaway: the most important thing is the placement of a3. 
% change L to change k
% change a3 to change D (or a32, but thats more constrained by tau mask)
% change a3 or a32 to change Q0, and thereby D

% % for sensitivity:

% % option 1:
% D     = 0.5;
% L     = 320000;
% Dd    = L/A*1000;

% % option 2:
D     = 0.5;
Dd    = 1.5;
L     = Dd/1000*A;           % 1/m * m^2 = m

% Step 7: compute the early- and late-time intercepts
a3    = bfra_pointcloudintercept(q,dqdt,3,'envelope','refqtls',[0.9 0.9]);
a32   = bfra_pointcloudintercept(q,dqdt,3/2,'envelope','refqtls',[0.5 0.5],'mask',itau);

% Step 8: upper bound Q, where b=3 and b=bhat intersect (m3/d)
Q0    = (a3/a32)^(1/(3/2-3));

% Step 9: hydraulic conductivity using the late time soln (m/d)
k     = (a32*A^(3/2)*phi/(4.804*L))^2; % *100/86400 m/d -> cm/s 
% k2  = 1.133/(D^3*L^2*a3*phi); % early time soln

% Step 10: aquifer depth (m)
D_s   = sqrt(Q0/(3.448*k*L^2/A)); % sqrt(Q0/(3.448*k*Dd*L)) % if using Dd

[Dd L k D_s Q0] % for sensitivity

% use RS05 solution:
%-------------------------------------------------------------------------------
a3    = bfra_pointcloudintercept(q,dqdt,3,'envelope','refqtls',[0.90 0.90]);
n     = bfra_conversions(bhat,'b','n','isflat',true);
fR2   = bfra_specialfunctions('fR2',n);

% option 1:
L     = 320000;
Dd    = L/A*1000;
D     = 0.5;

% % option 2:
% Dd    = 2.5;
% L     = Dd/1000*A;           % 1/m * m^2 = m
% D     = 0.5;


Q0    = (a3/ahat)^(1/(bhat-3));
k     = (phi*ahat/fR2)^(n+2)*(2^n*(n+1)*D^n*A^(n+3))/L^2; % cm/s
D_s   = sqrt(Q0/(3.448*k*L^2/A));

[Dd L k D_s Q0] % for sensitivity

%-------------------------------------------------------------------------------

% NOTE: changing L doesn't change D: 
% If L comes in as 320000, k = 922, D = 17.9
% If L = Dd*A, with Dd = 0.5, then L = 2.16e7, k = 0.21, D = 17.9

% but using the early-time solution does, which doesn't make sense b/c D goes
% into the early time to get k, then that k goes into the equation to get D and
% you get a much higher value for D

% test using a more reasonable drainage density to compute L
Dd    = 2.5/1000;       % 1/m
L     = Dd*A;           % 1/m * m^2 = m
k     = (a32*A^(3/2)*phi/(4.804*L))^2*100/86400; % m/d -> cm/s 
D     = sqrt(Q0/(3.448*k*L^2/A)); % sqrt(Q0/(3.448*k*Dd*L)) % if using Dd

% test usign the early-time solution to get k
D     = 0.5; % reset D
k     = 1.133/(D^3*L^2*a3*phi)*100/86400; % early time soln
D     = sqrt(Q0/(3.448*k*L^2/A)); % sqrt(Q0/(3.448*k*Dd*L)) % if using Dd




% % bfra_refline(q,dqdt,'mask',itau,'refline','userfit','userab',[a32 3/2])

% 
% 
% k = 1.133/(1^3*L^2*a3*phi)*100/86400;

% for b=3/2, a should have units m^-3/2 d^-1/2


% Q0_2 = (tau0*a3)^(1/(1-3))
% Qexp_2 = Q0_2*(2-bhat)/(3-bhat)

% i think this shows something important which is that phi is being computed
% based on the intersection of the bhat and b=3 lines as in Q0_troch, but Q0
% and Qexp are not being computed for that intersection point. Instead, can phi
% be computed in a way that corresponds to Qhat? I think I would first need k, 


% vline(Q0_troch)
% vline(Q0)
% vline(Qexp)



