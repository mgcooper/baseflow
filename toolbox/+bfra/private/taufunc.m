function [taufunc,tau] = taufunc(a,b,Q)
   %TAUFUNC Return inline function for tau or the value of tau.
   %
   %  [taufunc,tau] = taufunc(a,b,Q)
   %
   % See also getfunction
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % This was called by eventtau, replaced that with call to getfunction. This
   % is not called by any toolbox functions, but it demonstrates how to return
   % either the handle or the evaluated function, so I retained it for
   % reference.

   % first get tau function
   taufunc = @(a,b,Q) 1./a.*Q.^(1-b);
   if nargin == 0
      tau = taufunc;
   elseif nargin == 3
      tau = taufunc(a,b,Q);
   else
      error('either zero or three inputs required');
   end
end