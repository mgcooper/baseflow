function Props = aquiferprops(q,dqdt,alate,blate,phi,A,D,L,soln,varargin)
%AQUIFERPROPS estimate aquifer properties
% 
% Syntax
% 
%     Props = aquiferprops(q,dqdt,alate,blate,phi,A,D,L,soln,varargin)
% 
% Description 
% 
%     Estimate aquifer properties hydraulic conductivity k, depth D, and
%     critical baseflow Q0 
% 
% Required inputs
% 
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
% Optional name-value inputs
% 
%  earlyqtls   =  reference quantiles that together define a pivot point
%                 through which the straight line must pass (early time fit)
%  lateqtls    =  reference quantiles that together define a pivot point
%                 through which the straight line must pass (late time fit)
%  mask        =  logical mask to exclude data
%  Dd          =  drainage density. if provided, the relationship L=Dd*A will be
%                 used to compute L instead of the input L value
% 
% See also fitphi
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%-------------------------------------------------------------------------------
% input parsing
%-------------------------------------------------------------------------------
p = inputParser;
p.FunctionName = 'bfra.aquiferprops';

addRequired(p, 'q',                          @(x)isnumeric(x));
addRequired(p, 'dqdt',                       @(x)isnumeric(x));
addRequired(p, 'alate',                      @(x)isnumeric(x));
addRequired(p, 'blate',                      @(x)isnumeric(x));
addRequired(p, 'phi',                        @(x)isnumeric(x));
addRequired(p, 'A',                          @(x)isnumeric(x));
addRequired(p, 'D',                          @(x)isnumeric(x));
addRequired(p, 'L',                          @(x)isnumeric(x));
addRequired(p, 'soln',                       @(x)ischar(x));
addParameter(p,'earlyqtls',   [0.95 0.95],   @(x)isnumeric(x));
addParameter(p,'lateqtls',    [0.5 0.5],     @(x)isnumeric(x));
addParameter(p,'mask',        true(size(q)), @(x)islogical(x));
addParameter(p,'Dd',          nan,           @(x)isnumeric(x));
addParameter(p,'Q0',          nan,           @(x)isnumeric(x));
addParameter(p,'plotfit',     false,         @(x)islogical(x));

parse(p,q,dqdt,alate,blate,phi,A,D,L,soln,varargin{:});

earlyqtls   = p.Results.earlyqtls;
lateqtls    = p.Results.lateqtls;
mask        = p.Results.mask;
Dd          = p.Results.Dd;
Q0          = p.Results.Q0;
plotfit     = p.Results.plotfit;

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
%     (8) q = 0.862 * k * D^2 / (B * (1 + 1.115*k*D/(f*B^2)*t )^2)
% 
% 2. Equation 9 provides late time average water table thickness - obtained by
% integrating the inverse incomplete beta function phi(x/B) from 0->B = 0.773
%     (9) hbar = 0.773 * D / (1 + 1.115*k*D/(f*B^2)*t ) 
% 
% 3. Sub 9 into 8 to get an expression for q in terms of hbar rather than D
% (note that hbar changes wrt time so q varies with time)
%     (10) q = 1.443 * k/B * hbar^2
% 
% 4. integrate 10 along L to get basin outflow, sub Dd for L/A
%     (11) Q = 5.772*k*hbar^2*Dd*L
% 
% 5. repeat step 4 for early time, by setting t=0 in Eq 8 (step 1) 
%     (12) Q0 = 3.450 * k * D^2 * Dd * L
% 
% 6. set a1*Q^b1 = a2*Q^b2 and solve for Q - the intersection of the early- and
% late-time -dQ/dt lines on the point cloud - this is Q0
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

% check if Q0 was provided, if so, save it
if ~isnan(Q0)
   Q0check = Q0;
else
   Q0check = nan;
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

Dcheck = sqrt(Q0check/(3.448*k*L^2/A));
                                    
% package the output
Props.k     = k;
Props.Q0    = Q0;
Props.D     = D;
Props.a1    = aearly;
Props.b1    = bearly;
Props.a2    = alate;
Props.b2    = blate;
Props.D2    = Dcheck;
Props.input = p.Results;

%-------------------------------------------------------------------------------

% these can be used to get D directly from alate. for RS05, this will return the
% D that was used to get k in the above method. These expressions don't use
% cearly/clate (c1/c2 in the paper) b/c D is included in c2 for RS05, and there
% isn't an easy way to express D in terms of c2 for that case. 

% % RS05 non-linear late time:
% D = ((fR2/(alate*phi))^(n+2) * ( k*L^2/(2^n*(n+1)*A^(n+3))))^(1/n);
% 
% RS05 non-linear late time using just the Q(t=0) expression:
% n = bfra.conversions(blate,'b','n','isflat',true)
% Bn = beta((n+2)/(n+3),1/2)
% D = sqrt(Q0*(n+3)*(n+1)/(4*Bn*L*k*Dd)) % try k=100
% 
% % RS06 non-linear sloped late time:
% D = (2*k*L*sin(theta)/(n+1)*((n+1)^2/(alate*(n+0.01)*phi*A))^(n+1))^(1/n);


% TO PICK BACK UP ON GETTING D FROM RS05, right now on the white board i have
% three expressions for D:
%  1. from setting a0Q^b0 = aQ^b where a0 is early time a, b0 = 3, and a/b are  late time a/b. 
%  2. from setting t=0 in the late-tie expression for q(t)
%  3. from the notes above
% 
% k is present in all of them, and phi is probably in 1 and 3, so I need to
% figure out if I can cancel somehow, i.e. find a third equation, and/or use the
% graphical Q0 solution to get D in terms of k, then plug into the phi method
% ... note that phi cancels when setting a1 = a2 so that may be the key
% 
% The three expressions are:
% 1. D = ((c1/c2)^((n+2)/(n+3))*Q0/k)^(1/2)
% 2. D = ( (Q0*(n+3)(n+1))/(4*Bn*L*k*Dd))^(1/2)
% 3. D = ((fR2/(alate*phi))^(n+2) * ( k*L^2/(2^n*(n+1)*A^(n+3))))^(1/n);
% 
% In 1: c1 = fR1/L^2, c2 = fR2*(L^2/(N*A^(n+3)))^(1/(n+2)), N = see RS06 table
% set a0Q^b0 = aQ^b, sub in c1,c2, and solve for D
% In 2, I had to derive the form of Eq 8 Troch for RS05 late time: q = Q/(2*L)
% q = Bn*k*D^2/((n+3)*(n+1)*B*(1+Bn^2/(2*(n+3))*k*D/(phi*B^2)*t)^((n+2)/(n+1)));
% put a 2*L on top and you get Q. Sub in Dd you get:
% Q = 2*L*Bn*k*D^2*2*Dd/((n+3)*(n+1)*(1+Bn^2/(2*(n+3))*k*D*4*Dd/phi*t)^((n+2)/(n+1)));
% fR2 = (n+2)*(B_R2/(n+3))^(1/(n+2))
% a = phi_2*4*k*D*L^2/((n+1)*phi*A^2)*((n+1)*A/(4*k*D^2*L^2))^((n+2)/(n+1)) 
% phi_2 = (n+2)*Bn^2/(2*(n+3))*((n+3)/Bn)^((n+2)/(n+1))), Bn = beta((n+2)/(n+3),1/2)
% set t=0:
% Q0 = 2*L*Bn*k*D^2*2*Dd/((n+3)*(n+1)) = 4*Bn*L*k*Dd*D^2/((n+3)*(n+1))
% from which we find:
% D = (Q0*((n+3)*(n+1))/(4*Bn*L*k*Dd))^(1/2);
% note that phi is eliminated in this version

% NOTE: the key thing in all of these is correctly equating early and late time
% so the math matches the graphical solution which is where we get Q0.


% ------------------------------------------------------------------------------

% the notes that start here are good in principle but I screwed up by
% introducing the third equation, see notes at the end where instead I just set
% a1 = a2 and solve for D but I still got a weird result 

% this is for PK62 / BS04. I am not sure why it doesn't work. The idea is that
% we have two equations and three uknowns:
% -dQ/dt = a0*Q^b0, a0 = 1.133/(k*phi*D^3*L)*Q^3
% -dQ/dt = a*Q^b, a = 4.804*k^(1/2)*L/(phi*A^(3/2))*Q^b
% the three unknowns are k, phi, and D. So we get a third equation from the
% expression above for D, which comes from setting the late-time solution for
% q(t=0): 
% D = sqrt(Q0/(3.448*k*L^2/A)) = c1/k^(1/2), c1 = sqrt((Q0*A/(3.448*L^2))
% therefore k = (c1/D)^2, plug that in to the first two equations:
% -dQ/dt = 1.133*D^2/(c1^2*phi*D^3*L^2)*Q^3 = c2/(phi*D)*Q^3, c2 = 1.133/(c1^2*L^2)
% -dQ/dt = 4.804*c1*L/(phi*A^(3/2)*D)*Q^b = c3/(phi*D)*Q^b, c3 = 4.804*c1*L/A^(3/2)
% set them equal at Q = Q0 and rearrange for D
% D  = (c2/c3*Q0^(3-blate))^(2/3)
% but the answer is non sensical, which could be because this is for b=3/2 in
% which case it reduces to:
% D  = (3/2*L)^(2/3)
% to get the correct answer I need to do this over again for RS05 instead of
% BS04 and then I can use blate, but might still have an issue with the
% definition of Q0.

% c1 = sqrt((Q0*A/(3.448*L^2)))
% c2 = 1.133/(c1^2*L^2)
% c3 = 4.804*c1*L/(A^(3/2))
% ... shoot ... now D cancels and we just get back to where we started:
% Q0 = (c3/c2)^(2/3) = (4.804/1.133)^(2/3)*(c1*L)^2/A

% c1 = Q0*A/(3.448*L^2);
% c2 = 1.133/(c1*L^2);                % = 3.9066 / (Q0 * A) 
% c3 = 4.804*sqrt(c1)*L/(A^(3/2));    % = 2.5871 * sqrt(Q0) / A
% D  = (c2/c3*Q0^(3-blate))^(2/3);    % = (3/2 * Q0^(3/2-blate) )^(2/3)
%                                     % c2/c3 = 1.51/Q0^(3/2)
%                                     % note: if blate = 3/2, then D=1.3162*Q0

% here begins the right way excep tfor the confusion about Dd units ad the fact
% that the first two D results are different

% NOTE: I think I made this more complicated by using the c1 = Q0... equation
% because that may come from setting them equal ... this is D just by setting a1
% = a2:
% c1 = 1.133/(L^2)
% c2 = 4.804*L/(A^(3/2))
% D = (c1/c2)^(1/3)*sqrt(Q0/k) % this should equal the next line
% D = (1.133/4.804)*sqrt(A*Q0/(k*L^2)) % this is correct
% D = (1.133/4.804)*sqrt(Q0/(k*L*Dd)) % this is wrong b/c Dd is in 1/km i think
% which gives a reasonable result, so maybe that is right ...

% ------------------------------------------------------------------------------
% RS05
% I started to do this for RS05/RS05 but stopped b/c I think it's a dead end b/c
% D is in the late-time unlike BS04 and I can use remote sensing or model data
% to get reference D, ... but then i went ahead with it s o here goes:

% -dQ/dt = a0*Q^b0, a0 = fR1/(k*phi*D^3*L^2)*Q^3 = c1/(k*phi*D^3), c1 = fR1/L^2
% -dQ/dt = a*Q^b, a = 4.804*k^(1/2)*L/(phi*A^(3/2))*Q^b
% UPDATE, line above is BS04 I think, but from whiteboard, RS05 late tiem:
% -dQ/dt = a*Q^b, a = fR2/phi*(k*L^2/(N*D^n*A^(n+3))^(1/(n+2)) =
% c2/phi*(k/D^n)^(1/(n+2)), c2 = fR2*(L^2/(N*A^(n+3)))^(1/(n+2)), N = see RS06 table

% to exactly track troch, on the white board right now, I would need to do the
% hbar integration for RS05 and sub that into the q(t) to get a simpler
% expression for q(hbar), then multiply by 2L to get Q, otherwise, 

% unlike PK62/BS04 (a1/a2), for which D is not involved in a2, D is involved in
% a1 and a2 for RS05, and it is also involved in Q(t=0) using the late-time
% solution, so we cannot solve for k directly from a2 like Troch does. 

% the thing I did differently from Troch is set a0Q^b0 = aQb at Q = Q0, which
% should be the value of Q at the intersection of the early and late time lines.
% Troch does this too, but he does it graphically to get a1/a2 then gets k from
% a1 and D. 

% with RS05, I can get D(Q0,L,k,Dd), and Q0 from point cloud, leaving k as the
% uknown, for which literature values could be used if necessary. since D is
% needed to get phi, I assume it is needed to get k, so I cannot get k using the
% phi method. The 


% ------------------------------------------------------------------------------



