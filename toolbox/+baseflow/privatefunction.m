function funcHandle = privatefunction(funcName)
   %PRIVATEFUNCTION Return handle to function in private/ folder.
   % 
   % funcHandle = privatefunction(funcName) returns a function handle to the
   % function saved in private/funcName.m where private/ is in the same
   % directory as this function. 
   % 
   % PRIVATEFUNCTION uses completions.m to generate a list of
   % available private functions for tab-completion and input validation.
   % 
   % See also: baseflow.internal.completions
   
   funcName = validatestring(funcName, ...
      baseflow.internal.completions('private'), mfilename, 'FUNCNAME', 1);
   
   funcHandle = str2func(funcName);
   
   % use this to confirm correct scoping
   % functions(funcHandle)
   
   % switch funcName
   %    case 'todatenum'
   %       funcHandle = @todatenum;
   %    otherwise
   %       error('Unknown function name.');
   % end
end