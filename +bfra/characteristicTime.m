function [tc,tfunc] = characteristicTime(a,b,Q0)
%bfra_characteristicTime compute the characteristic time

% this is set up to return the function handle if no arguments are
% passed in, or return a value for tc if a,b,Q0 are passed in
if nargin == 0
   tc      = @(a,b,Q0) (Q0.^(1-b).*(exp(b-1)-1))./(a.*(b-1));
   tfunc   = tc;
else
   if b == 1
      tfunc   = @(a) 1./a;
      tc      = tfunc(a);
   else
      tfunc   = @(a,b,Q0) (Q0.^(1-b).*(exp(b-1)-1))./(a.*(b-1));
      tc      = tfunc(a,b,Q0);
   end
end