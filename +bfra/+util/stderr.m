function [SE,CI,PM,mu,sig] = stderr(data,varargin)
%STDERR compute the standard error of the mean from the standard deviation
%
% [SE,CI,PM,mu,sig] = stderr(data,varargin) computes the compute the standard
% error of the mean from the standard deviation of the data and the sample size,
% and applies a critical t-value to compute 95% confidence intervals.
%
% SE = standard error = standard deviation / sqrt(N)
% PM = standard error scaled by student's t-distribution critical value
% CI = confidence bounds, mu +/- PM
%
% alpha only affects the CI. The SE is always stdv/sqrt(N). For large
% sample sizes, if alpha = 0.32, then t_c is ~1 and SE is ~(CI-mu)/2
%
% the standard deviation is the uncertainty of an individual measurement
% the standard error is the standard deviation of the mean i.e. 68% CI
% the 95% confidence interval half-width is ~1.96*SE
% the mean is reported as mu +/- 1.96*SE, but an actual t-value
% is used here rather than 1.96 to adjust for small sample sizes
%
% See also timetablereduce

%--------------------------------------------------------------------------
p = magicParser;
p.FunctionName = mfilename;
p.addRequired('data', @(x)isnumeric(x));
p.addParameter('alpha', 0.05, @(x)isnumeric(x));
p.addParameter('dim', 2, @(x)isnumeric(x));
p.parseMagically('caller');
alpha = p.Results.alpha;
dim = p.Results.dim;

% assume data is oriented columnwise, and we want the mean +/- stderr of each row
%--------------------------------------------------------------------------

% check for vector vs matrix input
[r,c,p] = size(data);
d = data;
if p>1
   error('input must be a vector or an array organized as columns')
elseif c == 1
   d = d(:);     % for the case of one row, make it a column
elseif c>r && dim == 2
   warning( ...
      ['computing the std err of each row of data, set ''dim'' to 1 or '   ...
      newline ...
      'transpose the data before input if you want std err of each column'] )
else
end

% this is set up to compute means across columns (each row is a sample),
% example application would be a timeseries of data from multiple sites,
% each column being a site, so the output is the average and std error
% at each timestep. if we want the mean and std error of each site
% relative to the entire period, we need to change this. For example,
% instead of transposing, we could just enforce one method, or use 'dim'
% arguments

if isvector(d)
   N = numel(d(~isnan(d)));
   mu = mean(d,'omitnan');
   sig = std(d,'omitnan');
   p = (1-alpha/2);
elseif ismatrix(d)
   N = sum(~isnan(d),dim);
   mu = mean(d,dim,'omitnan');
   sig = std(d,[],dim,'omitnan');
   p = (1-alpha/2).*ones(size(mu));
end

tc = tinv(p,N-1);             % tc has N-1 dof
SE = sig./sqrt(N);            % the sample has N dof
PM = tc.*SE;                  % CI half-width (error margin)

% samples with N=1 will have SE=0, t_c=nan, CI=nan. this sets SE nan
SE = bfra.util.setnan(SE,[],isnan(tc));

% for very small N (like 2-3), the stderr is meaningless, so replace
% with twice the std error for 95%, and 1*stderr for 68%
notOK = N<5;

% might figure out how to interpolate between 1 and 2, where 1 is for
% 68% CI's and 2 is for 95% CI's
if alpha == 0.05
   sf = 2;
elseif alpha == 0.1
   sf = 1.8;
elseif alpha == 0.32
   sf = 1.0;
else
   warning('sample sizes <5 may have meaningless std errs')
end

PM(notOK) = sf.*SE(notOK);
CI = mu+cat(dim,-PM,PM);

end



