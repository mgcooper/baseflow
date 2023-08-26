function varargout = todatenum(varargin)

   varargout = cell(1, numel(varargin));
   for n = 1:numel(varargin)
      varargout{n} = tryconvert(varargin{n});
   end
end

function T = tryconvert(T)
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