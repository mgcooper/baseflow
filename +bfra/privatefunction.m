function funcHandle = privatefunction(funcName)

   switch funcName
      case 'todatenum'
         funcHandle = @todatenum;
      otherwise
         error('Unknown function name.');
   end
end
