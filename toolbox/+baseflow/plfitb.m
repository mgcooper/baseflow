function varargout = plfitb(x,varargin)
   %PLFITB fit an unbounded Pareto Distribution to recession parameter tau
   %
   % Syntax
   %
   %     Fit = plfitb(x,varargin)
   %
   % Description
   %
   %     Fit = plfitb(x,varargin) returns Fit containing the Pareto Distribution
   %     fit to input data x, where x is continuous data believed to follow an
   %     untruncated Pareto distribution with some unknown xmin such that
   %     xhat=x-xmin. Any inputs to plfit can be passed in as varargin, where
   %     plfit is Aaron Clauset's function.
   %
   % Required inputs
   %
   %     x        data believed to follow an untruncated Pareto distribution
   %
   % Optional name-value inputs
   %
   %     xmin     scalar double indicating the lower bound of the distribution
   %     range    the range of scaling parameters considered (see plfit.m)
   %     limit    scalar double that sets the upper bound of fitted exponent
   %     method   char indicating one of two algorithms (Clauset's or Hanel's)
   %     bootfit  logical indicating whether to bootstrap the uncertainties (slow)
   %     nreps    scalar double indicating how many replicates in the boot fit
   %     plotfit  logical indicating whether to call plplot
   %
   % See also: plfit, plplotb, gpfitb
   %
   % Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

   % if called with no input, open this file
   if nargin == 0; open(mfilename('fullpath')); return; end

   % PARSE INPUTS
   [x, xmin, range, limit, method, bootfit, nreps, plotfit] = parseinputs( ...
      x, varargin{:});

   % MAIN FUNCTION
   x0 = x;
   [x,~] = prepCurveData(x,x);
   x = x(x>0);
   if isnan(xmin)
      switch method
         case 'clauset'
            [alpha,xmin,L,D] = baseflow.deps.plfit(x,'range',range,'limit',limit);
            if bootfit == true
               BootFit = plbootfit(x,range,limit,nreps);
            end
            % Undocumented feature, requires r_plfit function, not in toolbox.
         case 'hanel'
            [~,xmin] = baseflow.deps.plfit(x,'range',range,'limit',limit);
            [alpha,xmin,L,D] = r_plfit(x,'rangemin',xmin,'alpha_min',  ...
               range(1),'alpha_max',range(end));
            % if I had some max value to consider, I could pass 'rangemax'
      end
   else
      [alpha,~,L,D] = baseflow.deps.plfit(x,'xmin',xmin,'range',range,'limit',limit);
   end

   Fit.x       = x0; % keep the input data
   Fit.alpha   = alpha;
   Fit.b       = 1+1/Fit.alpha;
   Fit.tau     = xmin*(2-Fit.b)/(3-2*Fit.b);
   Fit.tau0    = xmin;
   Fit.L       = L;
   Fit.D       = D;
   Fit.k       = 1/(Fit.alpha-1);
   Fit.taumask = x0>xmin;

   if bootfit == true
      Fit.b_L = Fit.b - BootFit.b_sig;
      Fit.b_H = Fit.b + BootFit.b_sig;
      Fit.alpha_L = Fit.alpha - BootFit.alpha_sig;
      Fit.alpha_H = Fit.alpha + BootFit.alpha_sig;
      Fit.tau0_L = Fit.tau0 - BootFit.tau0_sig;
      Fit.tau0_H = Fit.tau0 + BootFit.tau0_sig;
      Fit.tau_L = Fit.tau - BootFit.tau_sig;
      Fit.tau_H = Fit.tau + BootFit.tau_sig;
      Fit.reps = BootFit.reps;
      BootFit = rmfield(BootFit,'reps');
      Fit.BootFit = BootFit;
   else
      % assign null confidence bounds so other functions will work
      Fit.b_L = Fit.b;
      Fit.b_H = Fit.b;
      Fit.alpha_L = Fit.alpha;
      Fit.alpha_H = Fit.alpha;
      Fit.tau0_L = Fit.tau0;
      Fit.tau0_H = Fit.tau0;
      Fit.tau_L = Fit.tau;
      Fit.tau_H = Fit.tau;
   end

   % also: b = (2*k+1)/(k+1)
   % and:  alpha = 1 + 1/k

   if plotfit == true
      alpha = Fit.alpha;
      xmin = Fit.tau0;
      aci = [Fit.alpha_H Fit.alpha_L];
      xci = [Fit.tau0_L Fit.tau0_H];
      baseflow.plplotb(x,xmin,alpha,'trimline',true,'alphaci',aci,'xminci',xci);
   end

   switch nargout
      case 1
         varargout{1} = Fit;
      case 2
         varargout{1} = 1+1/alpha;
         varargout{2} = alpha;
      case 3
         varargout{1} = 1+1/alpha;
         varargout{2} = alpha;
         varargout{3} = xmin;
   end

   % NOTE: for alpha ~= 3, and 1000 reps, abs(BootFit.alpha-Fit.alpha) should
   % be about 0.01-0.02. This is indeed the case for the data I have tested
   % from the Kuparuk (the error was about 0.03, but alpha was about 3.12). See
   % Figure 10 in Clauset et al. 2009.
end

%% LOCAL FUNCTIONS

% bootstrap confidence intervals
function Fit = plbootfit(x,range,limit,nreps)

   %[alpha,xmin,L,D] = baseflow.deps.plfit(x,'range',range,'limit',limit);
   [~,~,~,repsmat] = baseflow.deps.plvar( ...
      x, 'range', range, 'limit', limit, 'reps', nreps, 'silent');

   vars        = {'tau0','alpha','b','tau','ntail'};
   reps.ntail  = repsmat(:,1);
   reps.tau0   = repsmat(:,2);
   reps.alpha  = repsmat(:,3);
   reps.b      = baseflow.conversions(reps.alpha,'alpha','b');
   reps.tau    = reps.tau0.*(2-reps.b)./(3-2.*reps.b);

   for n = 1:numel(vars)
      var = vars{n};
      Fit.(var) = mean(reps.(var));
      Fit.([var '_sig']) = std(reps.(var));
      Fit.([var '_L']) = mean(reps.(var)) - 1.96*std(reps.(var));
      Fit.([var '_H']) = mean(reps.(var)) + 1.96*std(reps.(var));
   end

   Fit.reps = reps;
   % replaced this with ntail
   % Fit.numtau  = numel(x(x>Fit.tau0_avg));
end

%% INPUT PARSER
function [x, xmin, range, limit, method, bootfit, nreps, plotfit] = ...
      parseinputs(x, varargin)
   parser = inputParser;
   parser.FunctionName = 'baseflow.plfitb';

   parser.addRequired('x', @isnumeric);
   parser.addParameter('xmin', nan, @isnumeric);
   parser.addParameter('range', 1.01:0.01:25.01, @isnumeric);
   parser.addParameter('limit', [], @isnumeric);
   parser.addParameter('method', 'clauset', @ischar);
   parser.addParameter('bootfit', false, @islogical);
   parser.addParameter('bootreps', 1000, @isnumeric);
   parser.addParameter('plotfit', false, @islogical);

   parser.parse(x, varargin{:});

   xmin    = parser.Results.xmin;
   range   = parser.Results.range;
   limit   = parser.Results.limit;
   method  = parser.Results.method;
   bootfit = parser.Results.bootfit;
   nreps   = parser.Results.bootreps;
   plotfit = parser.Results.plotfit;
end

%% extra
% As a rough check on the sampling distribution of the parameter
% estimators, we can look at histograms of the bootstrap replicates.
% figure; subplot(1,3,1);
% histogram(reps.b);
% title('Bootstrap estimates of $b$');
% subplot(1,3,2);
% histogram(reps.tau0);
% title('Bootstrap estimates of $\tau_0$');
% subplot(1,3,3);
% histogram(reps.alpha);
% title('Bootstrap estimates of $\alpha$');

%    % it is incorrect to apply the standard formula so don't use this
%    for n = 1:numel(vars)
%       var = vars{n};
%       [SE,CI,~,mu,sig] = stderror(reps.(var));
%       Fit.([var '_avg']) = mu;
%       Fit.([var '_L']) = CI(1);
%       Fit.([var '_H']) = CI(2);
%       Fit.([var '_sig']) = sig;
%       Fit.([var '_SE']) = SE;
%    end


% % this might still be a good approach, just need to figure out how to get the
% stdv of xmin
% function Fit = bootstrap_alpha(x,range,limit)
%
%    % first get xmin, bootstrap won't change this
%    [~,xmin] = baseflow.deps.plfit(x,'range',range,'limit',limit);
%
%    % now bootstrap alpha
%    reps  = bootstrp(1000,@(x,xmin)plfit(x,'xmin',xmin),x,xmin);
%
%    Fit.alpha = mean(reps);
%    Fit.tau0 = xmin;
%    Fit.alpha_sig = std(reps);
%    %Fit.tau0_sig % this is why we use plbootfit b/c it returns xmin_sig
%    Fit.reps = reps;
%
%    % see the appendix
%    % N = numel(reps)
%    % alphatrue = (1 + alpha*(N-1))/N
%    % alphasig = N*(alphatrue-1)/((N-1)*sqrt(N-2))
%    % N*(alpha-1)/((N-1)*sqrt(N-2))
% end
