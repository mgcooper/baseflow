function [q,dqdt,dt,tq,rq,dq] = fitets(T,Q,R,varargin)
   %FITETS fit recession event using the exponential timestep method
   %
   %  Syntax
   %
   %     ETS = bfra.fitets(T,Q,R,derivmethod)
   %     ETS = bfra.fitets(_,'etsparam',fitwindow)
   %     ETS = bfra.fitets(_,'fitab',fitmethod)
   %     ETS = bfra.fitets(_,'plotfit',pickmethod)
   %     ETS = bfra.fitets(_,'ax',axis_object)
   %
   %  Required inputs
   %
   %     T     time (days)
   %     Q     discharge (L T^-1, assumed to be m d-1 or m^3 d-1)
   %     R     rainfall (L T^-1, assumed to be mm d-1)
   %
   %  Optional name-value inputs
   %
   %     etsparam    scalar, double, parameter that controls window size
   %     fitab       logical, scalar, indicates whether to fit a/b in -dQ/dt=aQb
   %     plotfit     logical, scalar, indicates whether to plot the fit
   %
   %  See also fitdqdt, fitvts
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % note: only pass in identified recession events (not timeseries of
   % flow) because this first fits the ENTIRE recession to estimate 'gamma'
   % which is just a in the linear model -dq/dt = aQ. Then gamma is used to
   % compute 'm', which is the window size, which changes (gets larger) as
   % time proceeds. Then it moves over the flow data in windows of size m
   % and finds the local linear slope (in linear space, not log-log) which
   % is an estimate of dq/dt and the average q within the window and those
   % two values are used to compute -dq/dt = aQ^b.

   persistent inoctave
   if isempty(inoctave); inoctave = exist("OCTAVE_VERSION", "builtin")>0;
   end

   % PARSE INPUTS
   [T, Q, R, etsparam, plotfit] = parseinputs(T, Q, R, varargin{:});

   % MAIN FUNCTION - Fit exponential function on the entire recession event

   t = T-T(1)+(T(2)-T(1)); % For datenums:

   % T.Format = 'dd-MMM-uuuu hh:mm'; % For datetimes:
   % t = days(T-T(1)+(T(2)-T(1)));

   % Prepare for fitting
   [xe,ye] = prepCurveData(t, Q./max(Q));

   % Fit gamma (a in the linear model -dq/dt = aQ)
   b0 = [mean(ye) 0.2 0];

   if inoctave
      opts = optimset('Display','off');
   else
      opts = statset('Display','off');
   end

   func = @(b,x)b(1)*exp(-b(2)*x)+b(3);
   try
      abc = nlinfit(xe,ye,func,b0,opts);
   catch % ME
      % rethrow(ME)
      if ~inoctave
         try
            abc = tryexpfit(xe,ye);
         catch ME
            rethrow(ME)
         end
      end
   end

   % Compute the ets parameters
   gamm = abc(2); % gamma = b, also a in dq/dt = aQ
   nmax = etsparam*max(t);
   mpar = 1+ceil(nmax.*exp(-1./(gamm.*t))); % Eq. 7

   % Initialize the fit
   [N,q,dqdt,~,dt,tq,rq,r2] = initfit(t,'eventdqdt');

   % isempty(q) occurs when gamma is very small and m blows up.
   % if all(isempty(q)) || numel(q)<4
   if any(1./(gamm.*t)-log(etsparam./(max(t)-1)) < 0) || numel(q)<4
      return
   end

   % move over the recession in windows of length m and fit dQ/dt
   n = 1;
   while n+mpar(n)<=N

      x = t(n:n+mpar(n));
      X = [ones(length(x),1) x];
      Y = Q(n:n+mpar(n));

      dQdt  = X\Y;                        % eq. 8
      yfit  = X*dQdt;
      r2(n) = 1-sum((Y-yfit).^2)/sum((Y-mean(Y)).^2); r2(r2<0) = 0;

      dqdt(n) = dQdt(2);                  % eq. 9
      tq(n) = mean(T(n:n+mpar(n)));
      rq(n) = mean(R(n:n+mpar(n)));
      dt(n) = t(n+mpar(n))-t(n);
      q(n)  = mean(Y,'omitnan');

      n = n+1;
   end

   inan = dqdt>0 | isnan(r2) | r2<=0;
   dqdt(inan) = NaN;

   % compute dq
   dq = dqdt.*dt; % need to check this, right now it isn't used anywhere

   % retime to the original timestep
   q = interp1(tq(~isnan(q)),q(~isnan(q)),T);
   dq = interp1(tq(~isnan(dq)),dq(~isnan(dq)),T);
   dqdt = interp1(tq(~isnan(dqdt)),dqdt(~isnan(dqdt)),T);
   tq = T;

   if plotfit == true
      % figure; plot(t,q); hold on; plot(tets,qets)
   end


   % tq_dt = datetime(tq,'ConvertFrom','datenum');
   % T_dt = datetime(T,'ConvertFrom','datenum');

   % ------------
   % gamma checks
   % ------------
   % figure; plot(xexp,yexp,'o',xexp,fnc(abc,xexp),'-');
   % this inequality must be >= 0
   % 1./(gamma.*t) - log(etsparam./(max(t)-1))
   % if gamma is between about -0.2 and 0 it blows up
   % gtest = -2:0.0001:-0.2;
   % figure; semilogy(gtest,exp(-1./(gtest.*1)));
   % ------------

   %------------------------------------------------------------------
   % older method that truncated the fit based on parameter m. turns out in some
   % cases this truncates too early for example say q has length 12 and m(9) = 2
   % but m(12) = 3, then on iteration 9, n+m(n) = 11, but N=length(q)-max(m) = 9
   % so the loop would end at 9 when it should go to 10.
   % the # of individual q/dqdt estimates will be less than the q/dqdt
   % values since the step size is increased by the amount m(end)
   %N     = length(t)-m(end);   % new # of events

   % i think this would work if we use for 1:N where N is numel(t)-max(m)
   % tqq   = hours(tq-tq(1)+(tq(2)-tq(1)))./24; % keep og T
   % q     = interp1(tq,q,t,'linear');
   % dqdt  = interp1(tq,dqdt,t,'linear');

end

%% INPUT PARSER
function [T, Q, R, etsparam, plotfit] = parseinputs(T, Q, R, varargin)

   parser = inputParser;
   parser.FunctionName = 'fitets';
   parser.addRequired('T', @isnumeric);
   parser.addRequired('Q', @isnumeric);
   parser.addRequired('R', @isnumeric);
   parser.addParameter('etsparam', 0.2, @isnumeric); % default=recommended 20%
   parser.addParameter('plotfit', false, @islogical);
   parser.parse(T,Q,R,varargin{:});

   etsparam = parser.Results.etsparam;
   plotfit = parser.Results.plotfit;
end

%% TRY EXPFIT
function abc = tryexpfit(xexp,yexp)

   % Set up fittype and options.
   ftexp = fittype( ...
      'a*exp(-b*x)+c' , ...
      'independent','x', ...
      'dependent','y' ...
      );

   optsexp = fitoptions( ...
      'Method','NonlinearLeastSquares', ...
      'Display','Off',...
      'StartPoint',[1e-6 1e-6 1e-6] ...
      );

   % Fit model to data.
   fitexp = fit( xexp, yexp, ftexp, optsexp );
   abc = coeffvalues(fitexp);
end
