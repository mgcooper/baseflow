function str = getstring(request,varargin)
%GETSTRING get latex-formatted string for equations in the bfra library
% 
% Syntax
% 
%     str = getstring(request,varargin)
% 
% Description
% 
%     str = getstring(request) returns latex-formatted string for
%     requested string.
% 
%     str = getstring(request,'units',true) returns latex-formatted
%     string for requested string with units. Default behavior is 'units',false.
%  
% Optional inputs
% 
%     'aQb', 'Q', 'dQ/dt'
% 
% Example
% 
%     str = bfra.getstring('Q','units',true)
%     str =
%           '$Q \quad [\mathrm{m}^3 \;\mathrm{d}^{-1}]$'
% 
% See also bfra.aQbString
% 
% Matt Cooper, 04-Nov-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end


% parse inputs
[request, units, interpreter] = parseinputs(request, varargin{:});

% main function
if units == true
   str = getStringWithUnits(request);
else
   str = getStringWithoutUnits(request);
end

% convert to tex
switch interpreter
   case 'tex'
      str = bfra.util.latex2tex(str);
   case 'latex'
      
   otherwise
      error('unrecognized interpreter')
end


% subfunctions
function str = getStringWithUnits(request)

switch request
   
   case 'Q'
      
      str = '$Q \quad [\mathrm{m}^3 \;\mathrm{d}^{-1}]$';
      
   case {'dQdt','dqdt','dq/dt','dQ/dt'}
      
      str = [ '$-\mathrm{d}Q/\mathrm{d}t \quad[\mathrm{m}^3\;' ...
         '\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];
      
   case {'d2Qdt','d2Qdt2','dq2/dt','dq2/dt2'}

      str = [ '$-\mathrm{d}^2Q/\mathrm{d}t^2 \quad[\mathrm{m}^3\;' ...
         '\mathrm{d}^{-1}\;\mathrm{d}^{-2}]$'];

   case 'R'
      
      str = 'Rainfall $\quad [\mathrm{mm} \;\mathrm{d}^{-1}]$';
      
      % this might be simpler need to compare
      % str = 'Rainfall [mm d$^{-1}$]';
      
   case {'dndt','dn/dt'}
      
      str = [ '$\mathrm{d}\eta/\mathrm{d}t \quad[\mathrm{cm}\;' ...
         '\mathrm{a}^{-1}]$'];
      
   case 'aQb'
      
      str = ['$-\mathrm{d}Q/\mathrm{d}t$ = aQ$^b'                    ...
         '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}\;\mathrm{d}^{-1}]$'];
      
   case {'Q(t)','q(t)'}
      str = ['$Q = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)}'                ...
         '\quad[\mathrm{m}^3\;\mathrm{d}^{-1}]$'];
      
   case {'tau','Tau'}
      str = '$\tau \quad$ [days]';
      
end


function str = getStringWithoutUnits(request)

switch request
   
   case 'Q'
      str = '$Q$';
      
   case {'dQdt','dqdt','dq/dt','dQ/dt'}
      
      str = '$-\mathrm{d}Q/\mathrm{d}t$';
      
   case {'d2Qdt','d2Qdt2','dq2/dt','dq2/dt2'}
      
      str = '$-\mathrm{d}^2Q/\mathrm{d}t^2$';

   case {'dndt','dn/dt'}
      
      str = '$\mathrm{d}\eta/\mathrm{d}t$';
      
   case 'aQb'

      str = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';

   case {'Q(t)','q(t)'}

      str = '$Q = [Q_0^{-(b-1)}+a(b-1)t]^{-1/(b-1)}$';
      %str = '$Q(t) = [Q_0^{-(b-1)}+at(b-1)]^{-1/(b-1)}$';
      
   case {'tau','Tau'}
      str = '$\tau$';
      
   case {'R','Rainfall'}
      str = 'Rainfall';
end


function [request, units, interpreter] = parseinputs(request, varargin);

p = inputParser;
p.FunctionName  = 'bfra.getstring';
p.CaseSensitive = false;

addRequired(p, 'request', @(x)ischar(x) );
addParameter(p, 'units', false, @(x)islogical(x) );
addParameter(p, 'interpreter', 'latex', @(x)ischar(x) );

parse(p,request,varargin{:});
units = p.Results.units;
interpreter = p.Results.interpreter;

if bfra.util.isoctave
   interpreter = 'tex';
end
