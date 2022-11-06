function ETS = fitets(T,Q,R,varargin)
%FITETS fits recession event using the exponential timestep method
%
%  Syntax
%     ETS = bfra.fitets(T,Q,R,derivmethod)
%     ETS = bfra.fitets(_,'etsparam',fitwindow)
%     ETS = bfra.fitets(_,'fitab',fitmethod)
%     ETS = bfra.fitets(_,'plotfit',pickmethod)
%     ETS = bfra.fitets(_,'ax',axis_object)
% 
%  Required inputs
%     T     =  time (days)
%     Q     =  discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
%     R     =  rainfall (L T^-1, assumed to be mm d-1)
%     derivmethod = method to compute numerical derivative dQ/dt. Options are
%     'VTS','ETS','B1','B2','F1','F2','C2','C4','SGO','SPN','SLM'. default: ETS
% 
%  Optional name-value pairs
% 
%     etsparam = scalar, double, parameter that controls window size
%     fitab    =  logical, scalar, indicates whether to fit a/b in -dQ/dt=aQb
%     plotfit  =  logical, scalar, indicates whether to plot the fit
% 
%  See also fitdqdt

% note: only pass in identified recession events (not timeseries of
% flow) because this first fits the ENTIRE recession to estimate 'gamma'
% which is just a in the linear model -dq/dt = aQ. Then gamma is used to
% compute 'm', which is the window size, which changes (gets larger) as
% time proceeds. Then it moves over the flow data in windows of size m
% and finds the local linear slope (in linear space, not log-log) which
% is an estimate of dq/dt and the average q within the window and those
% two values are used to compute -dq/dt = aQ^b.

%-------------------------------------------------------------------------------
   p = MipInputParser;
   p.FunctionName = 'fitets';
   p.addRequired('T',@(x)isnumeric(x)|isdatetime(x));
   p.addRequired('Q',@(x)isnumeric(x));
   p.addRequired('R',@(x)isnumeric(x));
   p.addParameter('etsparam',0.2,@(x)isnumeric(x)); % default=recommended 20%
   p.addParameter('fitab',true,@(x)islogical(x));
   p.addParameter('plotfit',false,@(x)islogical(x));
   p.parseMagically('caller');
%-------------------------------------------------------------------------------

   % first we call the fitting algorithm
   [q,dqdt,dt,tq,rq,rsq] = fitdQdt(T,Q,R,etsparam);
   
   % then we interpolate to the original timestep. See notes at bottom.
   ETS = retimeETS(T,Q,R,q,dqdt,dt,tq,rq,rsq);
   
   % then we fit a/b if requested. note, ETS comes back as a struct with
   % the ETS timetable from retimeETS as a field
   ETS = fitETSab(ETS,fitab);
   
   plotSmoothing(T,Q,plotfit);
   
end   
   
function plotSmoothing(T,Q,plotfit)
   
   if plotfit
      % might be worth trying to smooth/gapfill the data here
      Q0    = Q;
      Q     = fillmissing(Q,'spline');
      Q     = smoothdata(Q,'sgolay');
      dQ0   = movingslope(Q0,21,3,T(2)-T(1));
      dQ    = movingslope(Q,21,3,T(2)-T(1));

      figure; 
      subplot(1,2,1); scatter(T,Q0); hold on; plot(T,Q)
      subplot(1,2,2); loglog(Q0,-dQ0); hold on; loglog(Q,-dQ);
   end
   
end

function [q,dqdt,dt,tq,rq,rsq] = fitdQdt(T,Q,R,etsparam)
   
   if isdatetime(T)
      dtog  = T(2)-T(1);
      T     = datenum(T);
   end
   
   % Fit exponential function on the entire recession event
         T0    = T;
         t     = T-T(1)+(T(2)-T(1)); % keep og T
   [xexp,yexp] = prepareCurveData(t, Q./max(Q));
   
   % fit gamma
   b0      = [mean(yexp) 0.2 0];
   opts    = statset('Display','off');
   fnc     = @(b,x)b(1)*exp(-b(2)*x)+b(3);
   try
      abc = nlinfit(xexp,yexp,fnc,b0,opts);
   end
   
   if ~exist('abc','var')
      abc = tryexpfit(xexp,yexp);
   end
   
   gamma    = abc(2);    % gamma = b
   % plot(xexp,yexp,'o',xexp,fnc(abc,xexp),'-');
   
   nmax     = etsparam*length(t);
   m        = 1+ceil(nmax.*exp(-1./(gamma.*t))); % Eq. 7
   
   % the # of individual q/dqdt estimates will be less than the q/dqdt
   % values since the step size is increased by the amount m(end)
   N        = length(t)-m(end);   % new # of events
   dqdt     = zeros(1,N);
   q        = zeros(1,N);
   dt       = zeros(1,N);
   tq       = zeros(1,N);
   rq       = zeros(1,N);
   rsq      = zeros(1,N);
   
   
   % move over the recession in windows of length m and fit dQ/dt
   for n = 1:N
      x       = t(n:n+m(n));
      X       = [ones(length(x),1) x];
      Y       = Q(n:n+m(n));
      dQdt    = X\Y;                               % eq. 8
      yfit    = X*dQdt;
      rsq(n)  = 1-sum((Y-yfit).^2)/sum((Y-mean(Y)).^2); rsq(rsq<0) = 0;
      
            dqdt(n)     = dQdt(2);                 % eq. 9
      dqdt(dqdt>0)      = NaN;
      dqdt(isnan(rsq))  = NaN;
      dqdt(rsq<=0)      = NaN;
               q(n)     = nanmean(Y);
               tq(n)    = mean(T0(n:n+m(n)));      
               rq(n)    = mean(R(n:n+m(n)));       
               dt(n)    = t(n+m(n))-t(n);
               
   end
   
   % figure; plot(t,q); hold on; plot(tets,qets)
   
end

function ETS = retimeETS(T,Q,R,q,dqdt,dt,tq,rq,rsq)
   
   % note: dt = m+1
   
   if all(isnan(q))
      return;
   end
   
   if ~isdatetime(T)
      T     = datetime(T,'ConvertFrom','datenum');
   end
   
   q     = q(:);dqdt=dqdt(:);dt=dt(:);tq=tq(:);rq=rq(:);rsq=rsq(:);
   Time  = datetime(tq,'ConvertFrom','datenum');
   ETS   = timetable(q,dqdt,dt,rq,rsq,'RowTimes',Time);
   dq    = ETS.dqdt.*ETS.dt;                       % add dq
   ETS   = addvars(ETS,dq);
   
   % this is needed to get the rain right, will need to revisit for sub-daily
   if T(2)-T(1) == days(1)
      ETS = retime(ETS,'daily','linear');             % retime to daily
   end
   
   % add the original T,Q,R on each day tq
   iq    = ismember(T,ETS.Time);
   R     = R(iq);
   T     = T(iq);
   Q     = Q(iq);
   
   ETS   = addvars(ETS,T,Q,R);

end

function ETS = fitETSab(T,fitabOrNot)
   
   % Fit the power law for a and b estimation (Roques et al., 2017)
   a = nan;
   b = nan;
   
   q  = T.q;
   dq = T.dqdt;
   rsq= T.rsq;
   
   if numel(q)>4 % only fit if there are > 4 values
      
      if fitabOrNot == true
         [fitets,~]  = LinRegFitW(log(q),log(-dq),rsq);
            pets     = coeffvalues(fitets);
            b     = pets(1);
            a     = exp(pets(2));
      end
      
      ETS.T    = T;
      ETS.a    = a;
      ETS.b    = b;
      ETS.ets  = true;     % I don't recall what these next two are for
      ETS.cts  = false;
      
   else % don't fit
      ETS = ets_setnan(T);
   end
   
   
end

function [fitted, gof] = LinRegFitW(x, y, weights)
   
   [  xData, ...
      yData, ...
      weights ]   = prepareCurveData( x, y, weights );
   
   % Set up fittype and options.
   ft             = fittype(     'poly1'                         );
   fopts          = fitoptions(  'Method', 'LinearLeastSquares'  );
   fopts.Weights  = weights;
   [fitted,gof]   = fit( xData, yData, ft, fopts );   % Fit model to data.
   
end

function out = ets_setnan(ETS)
   out.T    = ETS;
   out.a    = nan;
   out.b    = nan;
   out.ets  = nan;
   out.cts  = nan;
end


function abc = tryexpfit(xexp,yexp)
   
   % Set up fittype and options.
   ftexp   = fittype(   'a*exp(-b*x)+c' ,                   ...
                        'independent'   , 'x',              ...
                        'dependent'     , 'y'               );
   
   optsexp = fitoptions(   'Method'    , 'NonlinearLeastSquares',  ...
                           'Display'   , 'Off',                    ...
                           'StartPoint', [1e-6 1e-6 1e-6]          );
   
   % Fit model to data.
   fitexp  = fit( xexp, yexp, ftexp, optsexp );
   abc     = coeffvalues(fitexp);
   
end
