function [N,q,dqdt,dq,dt,tq,rq,r2] = initfit(q,fittype)
%INITFIT initialize arrays for common fitting routines in the bfra toolbox
% 
% Syntax
% 
%     [N,q,dqdt,dq,dt,tq,rq,r2] = initfit(q,fittype)
% 
% See also prepfits
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end


switch fittype
   
   case 'eventdqdt'
      N     = numel(q);
      q     = nan(N,1);
      dqdt  = nan(N,1);
      dq    = nan(N,1);
      dt    = nan(N,1);
      rq    = nan(N,1);
      r2    = nan(N,1);
      tq    = nan(N,1);
%       tq    = NaT(N,1);
%       tq    = NaT(N,1,'Format','dd-MMM-uuuu HH:mm:ss');
      
   case 'eventab'
      
end
