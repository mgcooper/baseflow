function summary = bootstrappercentiles(reps)
   %BOOTSTRAPPERCENTILES Summarize retained bootstrap samples without omission.
   % The midpoint convention linearly interpolates sorted samples at
   % probabilities (k-0.5)/n and clamps values beyond the endpoint knots.
   % Missing fields mean no bootstrap was requested. Nonfinite samples make
   % that parameter unavailable; no sample is removed or replaced.
   if nargin == 0
      reps = struct();
   end
   summary.probabilities = [0.025,0.975];
   summary.method = 'midpoint';
   names = {'alpha','b','tau0','tau','ntail'};
   for k = 1:numel(names)
      name = names{k};
      item = struct('bounds',[NaN,NaN],'available',false, ...
         'sampleCount',0,'invalidCount',0,'poleCount',0, ...
         'reason','notBootstrapped');
      if isfield(reps,name)
         values = reps.(name);
         item.sampleCount = numel(values);
         item.invalidCount = nnz(~isfinite(values));
         if strcmp(name,'tau') && isfield(reps,'alpha')
            item.poleCount = nnz(reps.alpha<=2);
         end
         if isempty(values)
            item.reason = 'emptyReplicates';
         elseif item.poleCount>0
            item.reason = 'tauPole';
         elseif item.invalidCount>0
            item.reason = 'nonfiniteReplicates';
         else
            % MATLAB exact and Octave method 5 use midpoint interpolation.
            item.bounds = reshape(quantile(values(:), ...
               summary.probabilities),1,[]);
            item.available = true;
            item.reason = '';
         end
      end
      summary.(name) = item;
   end
end
