function [N,q,dqdt,dq,dt,tq,rq,r2] = initfit(q,fittype);
%INITFIT initialize arrays for common fitting routines


switch fittype
   
   case 'eventdqdt'
      N     = numel(q);
      q     = nan(N,1);
      dqdt  = nan(N,1);
      dq    = nan(N,1);
      dt    = nan(N,1);
      rq    = nan(N,1);
      r2    = nan(N,1);
      tq    = NaT(N,1);
%       tq    = NaT(N,1,'Format','dd-MMM-uuuu HH:mm:ss');
      
   case 'eventab'
      
end