function TF = isodd(X, varargin)
   %ISODD Check if a number is odd
   %
   %  TF = ISODD(X) returns 1 (true) if X is odd, and 0 (false) otherwise.
   %
   %  TF = ISODD(X,'tol',TOL) allows for a tolerance in the check. This is
   %  useful for checking if floating point numbers are effectively integers.
   %  TOL defaults to 1e-6.
   %
   %  TF = ISODD(X,'tol',TOL,'method',METHOD) allows specifying the method used
   %  to determine oddness. Options: 'mod','bitwise'. The default method is
   %  'mod'.
   %
   % Example
   %  assert(isodd(3))
   %  assert(isodd(4))
   %  assert(isodd(3.00000001, 'tol', 1e-5))
   %
   % See also: iseven

   % parse inputs
   persistent parser
   if isempty(parser)
      parser = inputParser;
      parser.FunctionName = mfilename;
      parser.addRequired('X', @isnumeric);
      parser.addParameter('tol', 1e-10, @isnumeric);
      parser.addParameter('method', 'mod', @(x) ...
         any(validatestring(x, {'mod', 'bitwise'})));
   end
   parser.parse(X, varargin{:});
   tol = parser.Results.tol;
   method = parser.Results.method;

   % main code
   switch method
      case 'mod'
         TF = abs(X - round(X)) <= tol & mod(round(X),2) == 1;
      case 'bitwise'
         TF = abs(X - round(X)) <= tol & bitget(round(X),1) == 1;
   end
end

%% LICENSE
%
% BSD 3-Clause License
%
% Copyright (c) 2023, Matt Cooper (mgcooper)
% All rights reserved.
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
%    contributors may be used to endorse or promote products derived from
%    this software without specific prior written permission.
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
