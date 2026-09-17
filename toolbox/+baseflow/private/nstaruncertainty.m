function sig_Nstar = nstaruncertainty(b, sig_b)
   %NSTARUNCERTAINTY Uncertainty of N* = 1/(4-2b) from the uncertainty of b.
   %
   % Syntax
   %
   %     sig_Nstar = nstaruncertainty(b, sig_b)
   %
   % Description
   %
   %     sig_Nstar = nstaruncertainty(b, sig_b) propagates the uncertainty
   %     sig_b of the recession exponent b to N* = 1/(4-2b), the exponent
   %     of the linearized sensitivity coefficient. The derivative is
   %     dN*/db = 2/(4-2b)^2, so sig_Nstar = 2*sig_b/(4-2b)^2. The plain
   %     factor 2 holds only for b = 3/2, where 4-2b = 1.
   %
   % See also: dndtuncertainty

   % N* has a pole at b = 2, where the linearized solution does not apply.
   sig_Nstar = 2 .* sig_b ./ (4 - 2.*b).^2;
end
