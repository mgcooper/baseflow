%% Linear Reservoir Model
%% 
% In this tutorial , we will define the basic equations for a linear reservoir 
% model, which defines a linear relationship between groundwater storage and aquifer 
% discharge. In the second part of the tutorial, we evaluate the characteristic 
% drainage timescale for a linear storage-discharge relationship. 
%% Background
% Storage-discharge relationship
% The general equation for a storage-discharge relationship is defined here 
% as:
% 
% (1) $Q=c(S-S_r)^{1/(2-b)}, \quad b\ne2$    
% 
% where $S$ is aquifer storage, $Q$ is aquifer discharge, $c$ and $b$ are lumped 
% parameters that represent coefficients in the one-dimensional lateral groundwater 
% flow equation, and $S_r$ is a reference storage (arbitrary datum). 
% 
% During periods when precipitation, evaporation, and any other factor that 
% affects aquifer storage is negligible relative to aquifer discharge, the rate 
% of change of storage can be approximated by the conservation equation:
% 
% (2) $\frac{dS}{dt} = -Q, \quad (P-E \approx 0)$.
% 
% Combining these two equations, the rate of change of $Q$ can be expressed 
% as a power function of $Q$:
% 
% (3) $-\frac{dQ}{dt}=aQ^b$
% 
% where parameters $a$ and $c$ are related as $c=[a(2-b)]^{1/(2-b)}$. Integrating 
% Equation (3) over a time interval from $0\rightarrow t$, we obtain an expression 
% for discharge as a function of time:
% 
% (4) $Q(t)=[Q_0^{1-b}+a(b-1)t]^{1/(b-1)}$.
% 
% In practice, the storage-dicharge relationship is often represented using 
% Equation (3), with $S$ implicit, because normally $S$ cannot be observed, whereas 
% $Q$ can be approximated by measured values of streamflow draining a defined 
% land area. 
% 
% Baseflow recession analysis is dedicated to learning the parameters $a$ and 
% $b$, and doing so forms the primary basis for the baseflow toolbox.
% Linear reservoir model
% A linear reservoir model is one for which $b=1$. In this case, the relationship 
% between storage and discharge is:
% 
% (5) $Q=aS$
% 
% and it can be shown that the solution to (3) is classic exponential decay:
% 
% (6) $Q(t)=Q_0\exp{[-at]}$.
% 
% In the excercise below, we will show that the probability density function 
% of $Q(t)$ is:
% 
% (7) $p(Q(t)) = a\exp[-at]$,
% 
% the expected value for the so-called "characteristic timescale" $t_c$ is:
% 
% (8) $t_c = 1/a$,
% 
% and the expected value of $Q$ is:
% 
% (9) $Q_c = Q_0/2$.
%% Characteristic timescale analysis
% Dynamic systems are often characterized by the concept of a "characteristic 
% timescale", which is just the average "lifetime" of a state variable. For a 
% linear system, the characteristic timescale has a well-defined meaning in terms 
% of the so-called "e-folding" timescale, which is the timescale at which the 
% primary state variable equals $1/e$ of its initial value. The e-folding timescale 
% is analogous to the log10-based concept of a "half-life", where the state variable 
% equals one-half of its initial value. To derive the characteristic timescale, 
% we will use the tools of probability to first transform Equation (6) into a 
% probability density function and then compute the average lifetime of the state 
% variable, which is mathematically equivalent to the e-folding timescale. Then 
% we will compute the average (expected) value of the state variable, which here 
% is discharge $Q$.
% Define the symbolic variables and their properties

clearvars -except testCase demoFiles

syms c1 a Q Q0 Qmin Qmax t; assume([a c1 Q Q0 Qmin Qmax t],'clear')
sympref('FloatingPointOutput',false);

assume([a t Q0 Qmin Qmax],'positive')
assumeAlso(Qmin<Qmax)
% Define the expression for streamflow as a function of time, $Q(t)$

Q(t) = Q0.*exp(-a.*t)
% Derive the theoretical probability distribution for the drainage timescale, $t_c$
% Introduce a normalization constant $c_1$ that normalizes the integral over 
% all possible states of the sytem

c1expr = simplify(int(c1.*Q,t,0,inf))
%% 
% Substitute to solve for the normalization constant

c1 = c1/c1expr
%% 
% Find the pdf

Qtc_pdf  = c1.*Q
% Derive the characteristic drainage timescale, $t_c$
% Define the $t_c$ integrand, which is the scalar multiple of the pdf and the 
% independent variable time

dtc_dt   = Qtc_pdf.*t
%% 
% Integrate $\frac{dt_c}{dt}$ to find the mean lifetime aka the characteristic 
% timescale $t_c$

tc = int(dtc_dt,t,0,inf)
% Derive the expected value of discharge, $Q_c$
% Set up the integrand to find the expected value of $Q(t)$ 

dQc_dt = Q(t).*Qtc_pdf
%% 
% Integrate to find the expected value of $Q(t)$

Qc = int(dQc_dt,t,0,inf)
%% Verification
% Compare the results with the symbolic function bfra.sym.expectedvalue
%% 
% Define the limits of integration and call the function

tlowerIntegralLimit = 0;
tupperIntegralLimit = Inf;
[tc,Qexp] = bfra.sym.expectedvalue(Q,t,tlowerIntegralLimit,tupperIntegralLimit)
%% 
% See what happens when an upper limit is defined, equivalent to a lower limit 
% on streamflow

syms tmax positive 

[tc,Qexp] = bfra.sym.expectedvalue(Q,t,0,tmax)
%% 
% The implications of lower- and upper-limits to the pdf will become more apparent 
% in the non-linear analysis.
% 
% 
% 
% 
% 
% 
% 
%