%% Nonlinear Reservoir Model
%% 
% In this tutorial, we define the basic equations for a nonlinear reservoir 
% model, which defines a nonlinear relationship between groundwater storage and 
% aquifer discharge. In the second part of the tutorial, we evaluate the characteristic 
% drainage timescale for a nonlinear storage-discharge relationship. 
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
% Nonlinear reservoir model
% A nonlinear reservoir model is one for which $b\ne1$. In this case, the relationship 
% between storage and discharge is the same one given in (1):
% 
% (5) $Q=c(S-S_r)^{1/(2-b)}, \quad b\ne2$ 
% 
% and it can be shown that the solution to (3) is the power function given in 
% (4):
% 
% (6) $Q(t)=[Q_0^{1-b}+a(b-1)t]^{1/(b-1)}$.
% 
% In the excercise below, we will show that for $1\lt b \le 1.5$, the probability 
% density function of $Q(t)$ is:
% 
% (7) $p(Q(t)) = -\frac{{Q_{0}}^{b-2}\,a\,\left(b-2\right)}{{\left({Q_{0}}^{1-b}+a\,t\,\left(b-1\right)\right)}^{\frac{1}{b-1}}}$,
% 
% the expected value for the so-called "characteristic timescale" $t_c$ (which 
% is in fact non-characteristic for a nonlinear model) is:
% 
% (8) $t_c = -\frac{{Q_{0}}^{1-b}}{a\,\left(2\,b-3\right)} = -\frac{\tau_0}{2b-3}$,
% 
% and the expected value of $Q$ is:
% 
% (9) $Q_c = \frac{Q_{0}\,\left(b-2\right)}{b-3}$.
%% Characteristic timescale analysis
% Dynamic systems are often characterized by the concept of a "characteristic 
% timescale", which is just the average "lifetime" of a state variable. For a 
% linear system, the characteristic timescale has a well-defined meaning in terms 
% of the so-called "e-folding" timescale, which is the timescale at which the 
% primary state variable equals $1/e$ of its initial value. The e-folding timescale 
% is analogous to the log10-based concept of a "half-life", where the state variable 
% equals one-half of its initial value. 
% 
% For a nonlinear system, the "characteristic timescale" is better described 
% as "non-characteristic" because its value depends on the system state (which 
% is the defining feature of any nonlinear system). However, an expected value 
% for the "non-characteristic" timescale can be derived. To do so, we will use 
% the tools of probability to first transform Equation (6) into a probability 
% density function and then compute the average lifetime of the state variable, 
% which here is discharge $Q$. Then we will compute the expected value of the 
% state variable.
% Define the symbolic variables and their properties

clearvars
close all
clc

syms a b Q Q0 t c1; assume([a b Q Q0 t c1],'clear')
sympref('FloatingPointOutput',false);

assume([a t Q0],'positive')
assumeAlso(b>1)
assumeAlso(b<1.5)

tlowerIntegralLimit = 0;
tupperIntegralLimit = Inf;
% Define the expression for streamflow as a function of time, $Q(t)$

Q(t) = (Q0^(1-b)+a*(b-1).*t).^(1/(1-b))
% Derive the theoretical probability distribution for the drainage timescale, $t_c$
% Introduce a normalization constant $c_1$ that normalizes the integral over 
% all possible states of the sytem

c1expr = simplify(int(c1.*Q,t,tlowerIntegralLimit,tupperIntegralLimit))
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

tc = int(dtc_dt,t,tlowerIntegralLimit,tupperIntegralLimit)
% Simplify the expression for $t_c$
% The expression for $t_c$ can be simplified by noticing that the quantity $a^{-1} 
% Q_0^{1-b}$ has dimension time [_T_]. Defining this quantity in terms of a new 
% variable called $\tau_0$ leads to the following expression:
% 
% $$t_c = \frac{\tau_0}{3-2b}$$
% 
% The quantity $\tau_0$ will be described in more detail in the tutorial bfra_dynamical_systems.mlx. 
% Derive the expected value of discharge, $Q_c$
% Set up the integrand to find the expected value of $Q(t)$ 

dQc_dt = Q(t).*Qtc_pdf
%% 
% Integrate to find the expected value of $Q(t)$

Qc = int(dQc_dt,t,tlowerIntegralLimit,tupperIntegralLimit)
%% Verification
% Compare the results above with the symbolic function bfra.sym.expectedvalue
%% 
% Define the limits of integration and call the function

[tc,Qc] = bfra.sym.expectedvalue(Q,t,tlowerIntegralLimit,tupperIntegralLimit)
%% 
% The expression for $t_c$ can be simplified using the same variable substitution 
% described above. The expression for $Q_{c}$ can be simplified (and shown to 
% equal the one given above) by noting that $2+(1/(b-1))-(b/(b-1))=1$.
% 
% 
% 
% 
% 
%