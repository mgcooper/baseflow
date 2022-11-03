function [D,S] = aquiferthickness(b,tau,phi,Qb,varargin)
%BFRA.AQUIFERTHICKNESS compute the aquifer thickness from recession parameters
%b, tau, phi, and baseflow Qb.
% 
% Inputs:
%     b (dimensionless) = baseflow recession parameter b in -dQ/dt = aQ^b 
%     tau (Time) = aquifer drainage timescale, dQ/dS, where S = aquifer storage
%     phi (Length/Length) = drainable porosity 
%     Qb (Length/Time) = baseflow 
% 
% Outputs:
%     D (Length) = aquifer thickness
%     S (Length) = liquid water thickness of storage in D
% 
% D and S have dimension L_Q/T_Q * T_tau where L_Q and T_Q are the lenght and
% time dimesion of input Qb and T_tau is the time dimension of input tau. for
% example, if input Qb has dimension length L (or L^3) per time T in units cm/d
% and input tau has dimesion T in units d, then outputs D/S have dimension L in
% units cm. TLDR: make sure the time dimension of input Qb is the same as the
% time dimension of input tau so that the outputs D/S have the same length
% dimension as Qb.


if nargin == 4
   isflat = true;
else
   isflat = varargin{1};
end

N = bfra.conversions(b,'b','N','isflat',isflat);
D = tau./phi./(N+1).*Qb;
S = D.*phi; % convert layer thickness to storage