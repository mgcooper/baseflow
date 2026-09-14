function varargout = todatenum(varargin)
   %TODATENUM Convert input to datenum.
   %
   %  varargout = todatenum(varargin) converts each datetime input to a
   %  datenum array and returns the inputs in the same order. Inputs that
   %  are not datetime pass through unchanged.

   varargout = cell(1, numel(varargin));
   for n = 1:numel(varargin)
      varargout{n} = tryconvert(varargin{n});
   end
end

function T = tryconvert(T)
   if isa(T, 'datenum')
      return
   end
   if isdatetime(T)
      if isoctave
         %warning('attempting conversion from datetime to datenum')
      end
      try
         T = datenum(T); %#ok<*DATNM>
      catch e
         throwAsCaller(e)
      end
   end
end
