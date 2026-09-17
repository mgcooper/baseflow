function txt = breflinetext(b, isestimate, interpreter)
   %BREFLINETEXT Text of the b value of a reference line.
   %
   % Syntax
   %
   %     txt = breflinetext(b, isestimate, interpreter)
   %
   % Description
   %
   %     txt = breflinetext(b, isestimate, interpreter) returns the label
   %     of the reference line -dQ/dt = a*Q^b. A theoretical value carries
   %     the digits it needs and no more: b = 1 and b = 3 carry none, and
   %     b = 3/2 carries one.
   %
   %     isestimate true marks the value as a fitted one, with b-hat beside
   %     it and two decimals, so a reader can tell the fit from the
   %     reference lines it is drawn against.
   %
   %     interpreter selects 'latex' or 'tex'. Octave has no latex text
   %     interpreter, so the tex form drops the math delimiters.
   %
   % See also: labelrefline, plotrefline, plotdqdt

   % The number of decimals. A theoretical b is a whole number or a half.
   if isestimate
      digits = 2;
   elseif b == fix(b)
      digits = 0;
   elseif b == 3/2
      digits = 1;
   else
      digits = 2;
   end

   txt = sprintf('b=%.*f', digits, b);

   if strcmp(interpreter, 'latex')
      txt = ['$' txt '$'];
      if isestimate
         txt = [txt ' ($\hat{b}$)'];
      end
   elseif isestimate
      txt = [txt ' (bhat)'];
   end
end
