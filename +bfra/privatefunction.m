function funcHandle = privatefunction(funcName)

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