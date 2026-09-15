function varargout = getplotdata(varargin)
   %GETPLOTDATA Get data in current plot.
   %
   %  [xdata, ydata, zdata] = getplotdata(ax) returns the XData, YData, and
   %  ZData of the children of axes ax. It returns one of these, in order,
   %  for each requested output. With no input, ax is the current axes (gca).
   %  Each output holds the data of the children that have that property.
   %  getplotdata skips a child without it, for example a Text annotation
   %  (no XData) or an image (no ZData). If more than one child has the
   %  property, the output is a cell array with one element for each child.

   if nargin == 0
      ax = gca;
   else
      ax = varargin{1};
   end

   % Read each property only from the children that have it, so an
   % annotation or image child does not raise an error.
   childs   = get(ax,'Children');
   xdata    = get(findobj(childs, 'flat', '-property', 'XData'), 'XData');
   ydata    = get(findobj(childs, 'flat', '-property', 'YData'), 'YData');
   zdata    = get(findobj(childs, 'flat', '-property', 'ZData'), 'ZData');

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