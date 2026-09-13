function varargout = getplotdata(varargin)
   %GETPLOTDATA Get data in current plot.
   %
   %  [xdata, ydata, zdata] = getplotdata(ax) returns the XData, YData, and
   %  ZData of the children of axes ax. It returns one of these, in order,
   %  for each requested output. With no input, ax is the current axes (gca).

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