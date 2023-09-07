function varargout = getplotdata(varargin)
   %GETPLOTDATA Get data in current plot.

   if nargin == 0
      ax = gca;
   else
      ax = varargin{1};
   end

   childs   = get(ax,'Children');
   xdata    = get(childs, 'XData');
   ydata    = get(childs, 'YData');
   zdata    = get(childs, 'ZData');

   switch nargout
      case 1
         varargout{1} = xdata;
      case 2
         varargout{1} = xdata;
         varargout{2} = ydata;
      case 3
         varargout{1} = xdata;
         varargout{2} = ydata;
         varargout{3} = zdata;
   end
end