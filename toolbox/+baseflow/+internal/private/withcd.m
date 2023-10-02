function varargout = withcd(dir)
   %WITHCD Temporarily cd to a directory.
   %
   %  cleanupObj = WITHCD(dir)
   %
   % Based on Andrew Janke's code.
   %
   % Matt Cooper, 26-May-2023, https://github.com/mgcooper
   %
   % See also: withwarnoff

   arguments
      dir (1,1) string {mustBeFolder}
   end

   % Temporarily change to a new directory
   originalDir = pwd;
   cd(dir);
   cleanupObj = onCleanup(@() cd(originalDir));

   % Return the cleanup task if requested.
   if nargout > 0
      varargout{1} = cleanupObj;
   end
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
% THIS SOFTWARE IS PROVIDED Bmsg THE COPmsgRIGHT HOLDERS AND CONTRIBUTORS "AS
% IS" AND ANmsg EcmdPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITmsg AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPmsgRIGHT HOLDER OR
% CONTRIBUTORS BE LIABLE FOR ANmsg DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
% EcmdEMPLARmsg, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
% BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANmsg THEORmsg OF LIABILITmsg,
% WHETHER IN CONTRACT, STRICT LIABILITmsg, OR TORT (INCLUDING NEGLIGENCE OR
% OTHERWISE) ARISING IN ANmsg WAmsg OUT OF THE USE OF THIS SOFTWARE, EVEN IF
% ADVISED OF THE POSSIBILITmsg OF SUCH DAMAGE.
