function [k,Q0,D] = aquiferprops(q,dqdt,alate,blate,phi,A,D,L,soln,varargin)
%AQUIFERPROPS computes aquifer properties hydraulic conductivity k, depth D, and
%critical baseflow Q0
% 
% Required inputs:
%  q           =  discharge (L T^-1, e.g. m d-1 or m^3 d-1)
%  dqdt        =  discharge rate of change (L T^-2)
%  alate       =  late-time a parameter in -dqdt = aq^b ()
%  blate       =  late-time b parameter in -dqdt = aq^b (dimensionless)
%  phi         =  drainable porosity (L/L)
%  A           =  basin area contributing to baseflow (L^2)
%  D           =  saturated aquifer thickness (L)
%  L           =  active stream length (L)
%  soln        =  optional string indicating late-time theoretical solution
% 
% Optional name-value inputs:
%  earlyqtls   =  reference quantiles that together define a pivot point
%                 through which the straight line must pass (early time fit)
%  lateqtls    =  reference quantiles that together define a pivot point
%                 through which the straight line must pass (late time fit)
%  mask        =  logical mask to exclude data
%  Dd          =  drainage density. if provided, the relationship L=Dd*A will be
%                 used to compute L instead of the input L value
% 
%  See also fitphi

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = 'bfra_aquiferprops';

addRequired(p,'q',@(x)isnumeric(x));
addRequired(p,'dqdt',@(x)isnumeric(x));
addRequired(p,'alate',@(x)isnumeric(x));
addRequired(p,'blate',@(x)isnumeric(x));
addRequired(p,'phi',@(x)isnumeric(x));
addRequired(p,'A',@(x)isnumeric(x));
addRequired(p,'D',@(x)isnumeric(x));
addRequired(p,'L',@(x)isnumeric(x));
addRequired(p,'soln',@(x)ischar(x));
addParameter(p,'earlyqtls',[0.90 0.90],@(x)isnumeric(x));
addParameter(p,'lateqtls',[0.5 0.5],@(x)isnumeric(x));
addParameter(p,'mask',nan,@(x)islogical(x));
addParameter(p,'Dd',nan,@(x)isnumeric(x));

parse(p,q,dqdt,alate,blate,phi,A,D,L,soln,varargin{:});

earlyqtls   = p.Results.earlyqtls;
lateqtls    = p.Results.lateqtls;
mask        = p.Results.mask;
Dd          = p.Results.Dd;
%-------------------------------------------------------------------------------

% Note: This follows the method in Troch et al. 1993, which assumes D is unknown
% and the goal is to estimate k and Q0 to get D. Here, only Q0 uses the
% intersection of the early- and late-time lines, k is from late-time a. Troch
% uses a1/b1 = late time and a2/b2 = early time, whereas fitphi uses the
% opposite. The notes below follow Troch's paper so a1/b1 == late time, but the
% implementation uses early/late for clarity
% 
% bfra_fitphi assumes D is known and eliminates k to get phi by setting early-
% and late-time equations equal. Q0 is not involved in that approach.

% It should be possible to modify this using the fitphi method by settting
% early- and late-time equal to eliminate phi. 

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
% using early time soln for k increases k which decreases D, but the BS04 soln
% for k appears much more sensitive to this choice than RS05. The only
% difference b/w the BS04 and RS05 early-time solution is the numerator which is
% fixed to 1.113 for BS04 but is fR1 for RS05.

%-------------------------------------------------------------------------------

% check if Dd was provided; if so, adjust L
if ~isnan(Dd)
   L = Dd/1000*A;           % 1/m * m^2 = m
end

% Step 7: compute the early- and late-time intercepts
bearly = 3;
aearly = bfra.pointcloudintercept(q,dqdt,bearly,'envelope','refqtls',earlyqtls);

% late-time intercept either Boussinesq 1904 or Rupp and Selker, 2005
switch soln
   case 'BS04'
      blate = 3/2;
      alate = bfra.pointcloudintercept(q,dqdt,blate,'envelope','refqtls',lateqtls,'mask',mask);
   case 'RS05'
      alate = bfra.pointcloudintercept(q,dqdt,blate,'envelope','refqtls',lateqtls,'mask',mask);
end

% Step 8: upper bound Q, where b=3 and b=bhat intersect (m3/d)
Q0 = (aearly/alate)^(1/(blate-bearly));

% Step 9: hydraulic conductivity using the late time soln (m/d)
switch soln
   case 'BS04'
      
      % method 1: phi is known, D is not
      % --------------------------------
      
      % late time
      clate    = 4.804*L/A^(3/2);
      k        = (alate*phi/clate)^2;  % *100/86400 m/d -> cm/s 
      
      % early time
      % cearly = 1.133/(D^3*L^2);
      % k      = cearly/(aearly*phi);  % same as RS05
      
      % method 2: D is known, phi is not 
      % (equates early and late time to eliminate phi)
      % -----------------------------------------------
      % k   = ((cearly/aearly)*(alate/clate))^(2/3);
      
   case 'RS05'
      
      % method 1: phi is known, D is not
      % --------------------------------
      
      % late time:
      n     = bfra.conversions(blate,'b','n','isflat',true);
      fR2   = bfra.specialfunctions('fR2',n);
      clate = fR2*(L^2/(2^n*(n+1)*D^n*(A^(n+3))))^(1/(n+2));
      k     = (alate*phi/clate)^(n+2);
      
      % early time: 
      % fR1      = bfra_specialfunctions('fR1',n);
      % cearly   = fR1/(D^3*L^2);
      % k        = cearly/(aearly*phi);
      
      % method 2: D is known, phi is not 
      % (equates early and late time to eliminate phi)
      % -----------------------------------------------
      % k   = ((cearly/clate)*(alate/aearly))^((n+2)/(n+3));
      
      % Note: once clate/cearly are known, the expressions for k are identical
      % for both early and late time for RS05 and BS04, but I keep them inside
      % the switch block b/c we only use the late-time solution right now, and
      % it's a bit clearer to keep them separate. Note this applies to method 1
      % and method 2. The reason is because for b=3/2, n=0, so the exponenets on
      % the RS05 solutions equal the one for BS04 (the solutions are equivalent
      % at b=3/2).
end

% Step 10: aquifer depth (m)
D = sqrt(Q0/(3.448*k*L^2/A)); % sqrt(Q0/(3.448*k*Dd*L)) % if using Dd


%-------------------------------------------------------------------------------

% these can be used to get D directly from alate. for RS05, this will return the
% D that was used to get k in the above method. These expressions don't use
% cearly/clate (c1/c2 in the paper) b/c D is included in c2 for RS05, and there
% isn't an easy way to express D in terms of c2 for that case. 

% % RS05 non-linear sloped late time:
% D = ((fR2/(alate*phi))^(n+2) * ( k*L^2/(2^n*(n+1)*A^(n+3))))^(1/n);
% 
% % RS06 non-linear sloped late time:
% D = (2*k*L*sin(theta)/(n+1)*((n+1)^2/(alate*(n+0.01)*phi*A))^(n+1))^(1/n);










