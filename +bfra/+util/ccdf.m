function varargout = ccdf(data,varargin)

p = magicParser;
p.addRequired('data',@(x)isnumeric(x));
p.addParameter('makeplot',false,@(x)islogical(x));
p.parseMagically('caller');

[f,x] = ecdf(data);
F     = 1-f;

if makeplot == true
   figure; plot(x,F);
   xlabel('$x$');
   ylabel('$P(X\ge x)$');
end

switch nargout
   case 1
      varargout{1} = [F,x];
   case 2
      varargout{1} = F;
      varargout{2} = x;
end


