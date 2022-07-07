function ab = tsregr(x,y)

% mgc changed output from [b0,b1] to ab
% mgc added ,'omitnan' to all calls to median

% TSREGR Theil-Sen estimator.
%    [B0, B1] = TSREGR(X,Y) calculates straight line coefficients
%       Y = B0 + B1*X
%    for N data points {X,Y} using the Theil-Sen estimator.

% Joe Henning - Fall 2011

% mgc added this
x = x(:); y = y(:);
if isdatetime(x); x = datenum(x); end
% note: would be better to convert to duration using years, months, etc.
% functions, but for that, need to know desired timestep

if (length(x) ~= length(y))
   fprintf('   Error ==> length(x) must be equal to length(y)');
   b0 = NaN;
   b1 = NaN;
   return
end

n = length(x);

m = [];
for i = 1:n
   for j = i:n
      if (i ~= j && x(i) ~= x(j))
         slope = (y(j)-y(i))/(x(j)-x(i));
         m = [m slope];
      end
   end
end

xm = median(x,'omitnan');
ym = median(y,'omitnan');

b1 = median(m,'omitnan');
%b0 = median(y,'omitnan') - b1*median(x,'omitnan');
b0 = median(y - b1*x ,'omitnan');

ab(1) = b0;
ab(2) = b1;
