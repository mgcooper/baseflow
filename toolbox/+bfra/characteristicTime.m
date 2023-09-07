function [tc,tfunc] = characteristicTime(a,b,Q0)
   %CHARACTERISTICTIME compute the characteristic e-folding time for baseflow
   %
   % Syntax
   %
   %     [tc,tfunc] = characteristicTime(a,b,Q0)
   %
   % Description
   %
   %     [tc,tfunc] = characteristicTime(a,b,Q0) returns the characteristic time
   %     tc for baseflow to reach 1/e of its initial value. tfunc is an
   %     anonymous function for the characteristic time scale. Works for both
   %     linear and non-linear models. Note, for linear models, tc is equivalent
   %     to characteristic drainage timescale tau. For non-linear models, tc is
   %     not equivalent to tau.
   %
   %  See also
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % this is set up to return the function handle if no arguments are
   % passed in, or return a value for tc if a,b,Q0 are passed in
   if nargin == 0
      tc = @(a,b,Q0) (Q0.^(1-b).*(exp(b-1)-1))./(a.*(b-1));
      tfunc = tc;
   else
      if b == 1
         tfunc = @(a) 1./a;
         tc = tfunc(a);
      else
         tfunc = @(a,b,Q0) (Q0.^(1-b).*(exp(b-1)-1))./(a.*(b-1));
         tc = tfunc(a,b,Q0);
      end
   end
end