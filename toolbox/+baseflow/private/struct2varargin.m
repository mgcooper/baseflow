function varargs = struct2varargin(S, varargin)
   %STRUCT2VARARGIN Convert parser 'Unmatched' to varargin format
   %
   %  VARARGS = STRUCT2VARARGIN(S) Converts a name-value struct S to
   %  {'name', 'value'} cell format returned as VARARGS.
   %
   %  VARARGS = STRUCT2VARARGIN(_, 'asstring') Returns VARARGS as a string
   %  array.
   %
   % NOTE this does exactly what namedargs2cell does
   %
   % See also parser2varargin, namedargs2cell

   narginchk(1, 2)
   opts.asstring = strcmp('astring', varargin{1});

   if opts.asstring == true
      varargs = reshape(transpose([string(fieldnames(S)), struct2cell(S)]),1,[]);
   else
      varargs = reshape(transpose([fieldnames(S) struct2cell(S)]),1,[]);
   end

   % % old method:
   % fields   = fieldnames(unmatched);
   % varargs  = {};
   % for n = 1:numel(fields)
   %    varargs{2*n-1}  = fields{n};
   %    varargs{2*n}    = unmatched.(fields{n});
   % end
end
