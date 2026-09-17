function [ anoms,norms,pctdif,pctanom ] = anomaly( data, norms )
   %ANOMALY Compute climatological anomalies and normals of column-wise data.
   %
   %  [anoms, norms, pctdif, pctanom] = anomaly(data, norms) subtracts the
   %  column normals norms from data to compute the anomalies anoms.
   %  Without norms, anomaly uses the nan-omitted mean of each column.
   %  pctdif is the anomaly as a percent of the normal, and pctanom is
   %  100 + pctdif. A row or column vector data gives column outputs.

   % also see climatology.m and season.m in CDT

   % convert to columns and get the normals if not provided
   [r,c,p] = size(data);
   if p>1
      error('input must be a vector or an array organized as columns')
   elseif r == 1
      data = data(:); % for the case of one row, make it a column
   elseif c>r
      data = data';
      warning('more columns than rows, assuming data needs to be transposed')
   end
   % if a column or row is passed in it doesn't make any difference if the
   % data is transposed, it's just for consistent i/o b/w vectors and arrays

   if nargin == 1
      norms = mean(data,1,'omitnan'); % take the average of each column
   end

   anoms = data - norms;
   ratio = anoms./norms;
   pctdif = 100.*ratio;
   pctanom = 100 + pctdif;
   % pctanom = 100.*data./normal;

end
