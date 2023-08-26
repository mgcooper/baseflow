function [ data_out,idx ] = rmnan(data_in,dim )
%RMNAN remove NaN values from data array
%
%  [data_out,idx] = rmnan(data_in,dim) removes nan values from data_in and
%  returns the data as data_out.
%
% See also setnan, setval

% this needs to be merged with setnan functionality to pass in logical indices

if iscell(data_in)
   if nargin == 1 || (nargin == 2 && dim == 1)
      idx = false(size(data_in));
      for n = 1:size(data_in,1)
         if all(isnan(data_in{n})); idx(n) = true; end
      end
   elseif nargin == 2 && dim == 2
      idx = false(size(data_in));
      for n = 1:size(data_in,2)
         if all(isnan(data_in{n})); idx(n) = true; end
      end
   end
   data_in(idx) = [];
   data_out = data_in;
else

   if nargin == 1
      idx = isnan(data_in);
      data_in(idx) = [];
      data_out = data_in;
   elseif nargin == 2
      if dim == 1
         idx =   isnan(data_in(:,1));
         data_in(idx,:) = [];
         data_out = data_in;
      elseif dim == 2
         idx = isnan(data_in(1,:));
         data_in(:,idx) = [];
         data_out = data_in;
      end
   end
end

