function y = nanmean(varargin)
   %NANMEAN Compute the sample mean value, ignoring NaNs.
   %
   % This function wraps the built-in function mean with the 'omitnan' flag,
   % i.e., mean(varargin{:}, 'omitnan').
   %
   % Y = NANMEAN(X) returns the sample mean of X ignoring NaNs.
   % Y = NANMEAN(X, DIM) operates along dimension DIM.
   % Y = NANMEAN(X, 'all') uses all values in X.
   % Y = NANMEAN(X, VECDIM) operates along dimensions in the vector VECDIM.
   % Y = NANMEAN(_, OUTTYPE) specifies the type in which the mean is performed,
   %     and the type of Y. Available options are 'double', 'native', and
   %     'default'. If OUTTYPE is 'double', Y has class double for any input X.
   %     If OUTTYPE is 'native', Y has the same class as X. If OUTTYPE is
   %     'default', Y has the same class as X if X is floating point, otherwise
   %     Y has class double. Default option is 'default'.
   %
   % See also MEAN, NANMEDIAN, NANSTD, NANVAR, NANMIN, NANMAX, NANSUM.

   % PARSE INPUTS
   narginchk(1,3);

   % MAIN CODE
   y = mean(varargin{:},'omitnan');
end

%% LICENSE

% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper) All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
%    contributors may be used to endorse or promote products derived from this
%    software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.