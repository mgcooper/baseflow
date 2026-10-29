function varargout = specialfunctions(funcname, varargin)
   % SPECIALFUNCTIONS Special function ibarary required for recession analysis.
   %
   %  fR1 = specialfunctions('fR1', n) and fR2 = specialfunctions('fR2', n)
   %  return the early-time and late-time constants of Rupp and Selker
   %  (2005) for the conductivity profile k(z) = kD*(z/D)^n.
   %
   % See also: Qnonlin
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % L2      = L.*L;
   % phiA2   = phi.*A.^2;
   % phiL2   = phi.*L.^2;
   % kL2     = kD.*L.^2;

   switch funcname

      case 'fR1'

         n     = varargin{1};
         fR1   = getfR1(n);

         % prep output
         varargout{1}   = fR1;

         % % for extended functionality
         % kD    = varargin{2};
         % L     = varargin{3};
         % phi   = varargin{4};
         % b     = 3;
         % N     = -3;
         % c     = fR1./(kD.*phi.*L.^2);

      case 'fR2'

         n     = varargin{1};
         fR2   = getfR2(n);

         % prep output
         varargout{1}   = fR2;

         % % for extended functionality
         % kD    = varargin{2};
         % L     = varargin{3};
         % phi   = varargin{4};
         % A     = varargin{5};
         % 
         % b     = (2.*n+3)./(n+2);
         % N     = -n./(n+2);
         % c     = fR2./phi.*( (kD.*L.*L) ./ (2.^n.*(n+1).*A.^(n+3)));

      case 'fLo'
         
         assert(numel(varargin) >= 4)
         kD = varargin{2};
         L = varargin{3};
         phi = varargin{4};
         
         phiL2 = phi.*L.^2;

         h0overD = 0.0; % assume h0=0, fLo=1.1361         
         soln = 2; % jul 2024 - soln was unset, so I used Lockington.
         fLo = getfLo(h0overD, soln);

         b = 3;
         N = -3;
         c = fLo./(kD.*phiL2);
   end
end

%% Local Functions
function fR1 = getfR1(n)
   % early-time constant of Rupp and Selker (2005), eqs 33 and 56, m = 1.
   % gamma is their A (eq 28). fR1/(n+1) is their Phi1 (Table 1: 1.108 at
   % n = 0), because a1 here uses kD, as their eq 54 does.
   BR1     = beta(n+2, 2);
   gamma   = 2 * (n+2) .* BR1;
   mu      = (4 - 3*gamma - sqrt(gamma.^2 - 2*gamma + 4)) ./ (4 - 2*gamma);
   fR1     = (1-mu) .* (n+1) .* (n+2) ./ (2 * (1 - 2*mu));
end

function fR2 = getfR2(n)
   % late-time constant of Rupp and Selker (2005). At n = 0 it is the
   % Brutsaert and Nieber (1977) constant 4.804 that fitphi uses for BS04.
   % fR2/2 is their Phi2 (eq 59; Table 1: 2.402 at n = 0).
   BR2 = beta((n+2) ./ (n+3), 1/2);
   fR2 = (n+2) .* (BR2.^(n+3) ./ (n+3)) .^ (1./(n+2));
end

function fLo = getfLo(h0overD,soln)

   % various solutions exist, all depend on ratio of water level in stream
   % (h0) to initial water table level (h_infinity, or as I call it D)

   switch soln
      case 2              % Lockington

         a   = -0.4604;
         b   = 1.0734;
         c   = -0.9673;
         d   = 1.1361;

         fLo = a.*h0overD.^3 + b.*h0overD.^2 + c.*h0overD + d;

      case 20             % Hayek

         % not sure exactly how to represent Hayek's function, the
         % a/b/c/d values are functions of D, whereas Rupp gave a single
         % set for all D, I think, but that set might be an
         % approximation that works well for all D. See tabl 3 of Hayek

      case 21             % Basha
   end
end
