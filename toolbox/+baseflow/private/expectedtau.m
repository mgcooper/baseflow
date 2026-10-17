function tau = expectedtau(tau0, b)
   %EXPECTEDTAU Mean tau of a Pareto tail with recession exponent b.
   %
   % Syntax
   %
   %     tau = expectedtau(tau0, b)
   %
   % Description
   %
   %     tau = expectedtau(tau0, b) returns tau0*(2-b)/(3-2*b), the mean of a
   %     Pareto distribution with lower bound tau0 and pdf exponent
   %     alpha = 1/(b-1). It applies elementwise to tau0 and b.
   %
   %     The mean diverges at and beyond the tau pole at alpha = 2, which is
   %     3/2 <= b < 2, so tau is Inf there. For b < 1 or b >= 2 (alpha <= 1),
   %     no Pareto tail exists, so tau is nan. Either case raises
   %     baseflow:expectedtau:tauPole, with the count of values it affects.
   %     gpfitb, plfitb, plplotb, and getfunction call it, so they share
   %     these values and this warning.
   %
   % See also: getfunction, gpfitb, plfitb, plplotb, expectedQ

   % The masks take the shape of b, so they hold when tau0 is an array and
   % b is a scalar. A nan b falls in neither mask.
   diverges = b >= 3/2 & b < 2;
   notail = b < 1 | b >= 2;

   % The formula changes sign at the pole, but the mean of a positive
   % variable with a divergent integral is infinite.
   ratio = (2-b)./(3-2.*b);
   ratio(diverges) = inf;
   ratio(notail) = nan;
   tau = tau0.*ratio;

   if any(diverges(:) | notail(:))
      warning('baseflow:expectedtau:tauPole', ...
         ['%d of %d values of b give no finite mean tau. The mean diverges ' ...
         'for 3/2 <= b < 2 (1 < alpha <= 2) and is undefined for b < 1 ' ...
         'or b >= 2.'], ...
         nnz(diverges | notail), numel(b))
   end
end
