function varargout = dealout(varargin)
   %DEALOUT deal out function outputs
   %
   % [argout1, argout2] = dealout(argin1, argin2, ..., arginN]
   %
   % The number of output arguments does not have to match the number of inputs,
   % but they will be dealt out in the exact order they are dealt in i.e.
   % argout1 = argin1, argout2 = argin2, and so forth.
   %
   % Note: if the calling function tries to do something like this:
   % varargout = dealout(arg1) ... and no output is requested from the base
   % workspace, then the first element of arg1 will get sent back. For example:
   %
   % function celloutput = myfunction(varargin)
   %
   % ... function code
   %
   % varargout = dealout(cellarg1);
   %
   % % Then, in a script:
   % myfunction(...)
   %
   % % with no requested outputs, will return the first element of cellarg1. But
   % % if this syntax is used, nothing will be returned:
   %
   % function celloutput = myfunction(varargin)
   %
   % ... function code
   %
   % [varargout{1:nargout}] = dealout(cellarg1);
   %
   % Matt Cooper, 22 Jun 2023
   %
   % See also

   args = varargin;
   if numel(varargin{:}) == 1 && isstruct(varargin{1})
      try
         args = struct2cell(args{:});
      catch
      end
   end

   if nargout > numel(args)
      error('One input required for each requested output')
   end

   try
      % Syntax is [out1, out2, ..., outN] = dealout(in1, in2, ..., inN]
      [varargout{1:nargout}] = deal(args{1:nargout});

      % Note: this syntax is useful for forcing one output
      % [varargout{1:max(1,nargout)}] = deal(varargin{1:nargout});
   catch
      % Syntax is [out1, out2, ..., outN] = dealout(CellArray)
      varargout = args{:};
   end

   % TODO:
   % Compare with this format:
   % if ~iscell(x), x = num2cell(x); end
   % varargout = cell(1,nargout);
   % [varargout{:}] = deal(x{:});

   % Compare with fex function deal2
end