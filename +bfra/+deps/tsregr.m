function ab = tsregr(x,y)
% TSREGR Theil-Sen estimator.
%    [B0, B1] = TSREGR(X,Y) calculates straight line coefficients
%       Y = B0 + B1*X
%    for N data points {X,Y} using the Theil-Sen estimator.
%
% Joe Henning - Fall 2011

% LICENSE
% 
% Copyright (c) 2014, Joe Henning
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution
% * Neither the name of  nor the names of its
%   contributors may be used to endorse or promote products derived from this
%   software without specific prior written permission.
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

% mgc changed output from [b0,b1] to ab
% mgc added ,'omitnan' to all calls to median
% mgc convert to column on input

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
