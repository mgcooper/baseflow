function str = getstring(requestedstring,varargin)
%GETSTRING returns various latex-formatted strings
%
% INPUTS:
% 'aQb'
% 'Q'
% 'dQ/dt [m3 d-1]
%
% see also bfra.aQbString

%-------------------------------------------------------------------------------
p               = inputParser;
p.FunctionName  = 'getstring';
p.CaseSensitive = false;

addRequired(   p,'requestedstring',          @(x)ischar(x)     );
addParameter(  p,'units',           false,   @(x)islogical(x)  );

parse(p,requestedstring,varargin{:});
units = p.Results.units;
%-------------------------------------------------------------------------------

if units == true
   str   = getStringWithUnits(requestedstring);
else
   str   = getStringWithoutUnits(requestedstring);
end


function str = getStringWithUnits(requestedstring)

switch requestedstring
   
   case 'Q'
      
      str = '$Q \quad [\mathrm{m}^3 \;\mathrm{d}^{-1}]$';
      
   case {'dQdt','dqdt','dq/dt','dQ/dt'}
      
      str = [ '$-\mathrm{d}Q/\mathrm{d}t \quad[\mathrm{m}^3\;' ...
         '\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];
      
   case {'dndt','dn/dt'}
      
      str = [ '$\mathrm{d}\eta/\mathrm{d}t \quad[\mathrm{cm}\;' ...
         '\mathrm{a}^{-1}]$'];
      
   case 'aQb'
      
      str = ['$-\mathrm{d}Q/\mathrm{d}t$ = aQ$^b'                    ...
         '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];
      
   case {'Q(t)','q(t)'}
      str = ['Q = $[Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)}'                ...
         '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}]$'];
      
   case {'tau','Tau'}
      str = '$\tau \quad$ [days]';
      
end


function str = getStringWithoutUnits(requestedstring)

switch requestedstring
   
   case 'Q'
      str = '$Q$';
      
   case {'dQdt','dqdt','dq/dt','dQ/dt'}
      
      str = '$-\mathrm{d}Q/\mathrm{d}t$';
      
   case {'dndt','dn/dt'}
      
      str = '$\mathrm{d}\eta/\mathrm{d}t$';
      
   case 'aQb'
      str = '$-\mathrm{d}Q/\mathrm{d}t$ = aQ$^b$';
      
   case {'Q(t)','q(t)'}
      str = 'Q = $[Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)}$';
      
   case {'tau','Tau'}
      str = '$\tau$';
end
