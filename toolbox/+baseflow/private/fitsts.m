% function [q,dqdt,dt,tq,rq,dq] = fitsts(T,Q,R,varargin)
%    %FITSTS fit recession events using splines. not implemented.
%    %
%    %
%    %
%    % See also fitets, fitvts, fitcts
%    %
%    % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper
% 
%    switch method
%       case 'SPN'
% 
%          %       % NOTE: this is not implemented
%          %
%          %       % implement splinefit with matlab's optimal knot method
%          %     % ord         = opts.spn.order;
%          %       ord         = 3;
%          %       nbreaks     = 2+fix(length(T)/4);
%          %       breaks      = baseflow.splinebreaks(T,Q,nbreaks,ord);
%          %       pspline     = splinefit(T,Q,breaks,ord);  % piecewise cubic
%          %       dspline     = fnder(pspline,1); % ppdiff(p_spline,1) works too
%          %       Qspline     = ppval(pspline,T);
%          %       dQspline    = ppval(dspline,T);
%          %
%          %       q           = Qspline;
%          %       dq          = dQspline;
%          %       dqdt        = dQspline;
%          %       dt          = (T(2)-T(1)).*ones(size(T));
%          %       tq          = T;
% 
%       case 'SLM'
% 
%          %       % NOTE: this is not implemented
%          %
%          %       ord         = spnorder;
%          %       %nbreaks    = 2+fix(length(T1)/4);
%          %       %breaks     = unique(baseflow.splinebreaks(T1,Q1,nbreaks,ord));
%          %       pslm        = slmengine(T,Q,'degree',ord-1,'interiorknots',   ...
%          %                      'free','knots',100);
%          %       dQslm       = slmeval(T,pslm,1);    % differentiate
%          %       Qslm        = slmeval(T,pslm);      % evaluate
%          %       q           = Qslm;
%          %       dq          = dQslm;
%          %       dqdt        = dQslm;
%          %       dt          = (T(2)-T(1)).*ones(size(T));
%          %       tq          = T;
% 
%       case 'pchip'
% 
%       case 'SGO'
% 
%          %       % NOTE: this is not implemented
%          %
%          %
%          % %       ord         = opts.sgo.order;               % polynomial filter order
%          % %       fl          = opts.sgo.window;              % frame length
%          %       ord         = 3;
%          %       fl          = 7;
%          %       dt          = (T(2)-T(1));                  % time discretization
%          %       Qsgolay     = sgolayfilt(Q,ord,fl);
%          %       dQsgolay    = movingslope(Qsgolay,fl,ord,dt);
%          %       q           = Qsgolay;
%          %       dq          = dQsgolay;
%          %       dqdt        = dQsgolay;
%          %       dt          = (T(2)-T(1)).*ones(size(T));
%          %       tq          = T;
% 
%    end
% end
