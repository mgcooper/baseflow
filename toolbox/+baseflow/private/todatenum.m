function varargout = todatenum(varargin)
   %TODATENUM Convert input to datenum.

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
