function [f] = zeta(z)
%ZETA Riemann Zeta function
%
% usage: f = zeta(z)
%
% tested on version 5.3.1
%
%      This program calculates the Riemann Zeta function
%      for the elements of Z using the Dirichlet deta function.
%      Z may be complex and any size. Best accuracy for abs(z)<80.
%
%      Has a pole at z=1, zeros for z=(-even integers),
%      infinite number of zeros for z=1/2+i*y
%
%
% See also: Eta, Deta, Lambda, Betad, Bern, Euler

%Paul Godfrey
%pgodfrey@conexant.com
%3-24-01

% LICENSE
% 
% Copyright 2001 Paul Godfrey
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met: 
% 
% 1. Redistributions of source code must retain the above copyright notice, this
% list of conditions and the following disclaimer. 
% 
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.  
% 
% 3. Neither the name of the copyright holder nor the names of its contributors
% may be used to endorse or promote products derived from this software without
% specific prior written permission.  
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

zz=2.^z;
k = zz./(zz-2);

f=k.*bfra.deps.deta(z,1);

p=find(z==1);
if ~isempty(p)
   f(p)=Inf;
end

return

%a demo of this function is

% ezplot zeta
% grid on
% 
% figure(2)
% ezmesh('abs(zeta(x+i*y))',[0 1 .5 30])
% view(75, 4)
