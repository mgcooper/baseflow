function diagnoseKuparuk(root, outdir)
   %DIAGNOSEKUPARUK Record the public Kuparuk stages without changing them.
   %
   % diagnoseKuparuk(root, outdir) captures the TestBaseflow stages that
   % determine the Kuparuk exponent. It repeats eventtau to retain its arrays.
   % ROOT is a committed checkout. OUTDIR is an existing external directory.
   % The MAT file retains stage arrays. JSON records identities and summary.
   % A successful exit means capture completed, not that the product passed.

   % Preserve the initial path, folder, RNG state and figure handles
   % for cleanup.
   oldpath = path;
   olddir = pwd;
   oldrng = rng;
   oldfigs = findall(groot, 'Type', 'figure');
   cleanup = onCleanup(@() restorestate(oldpath, olddir, oldrng, oldfigs));
   assert(isfolder(outdir), 'The external output directory must exist.');
   cd(root);
   restoredefaultpath;
   addpath(fullfile(root, 'toolbox'));
   Setup('addpath');
   addpath(fullfile(root, 'tests'));

   % Record runtime details and resolved functions for cross-run comparisons.
   R.version = version;
   R.release = version('-release');
   R.arch = computer('arch');
   R.blas = version('-blas');
   R.lapack = version('-lapack');
   R.products = ver;
   R.threads = maxNumCompThreads;
   R.rngBefore = rng;
   names = {'baseflow.loadExampleData', 'baseflow.wrapevents', ...
      'baseflow.getevents', 'baseflow.eventfinder', 'baseflow.fitevents', ...
      'baseflow.fitab', 'baseflow.globalfit', 'baseflow.eventtau', ...
      'baseflow.plfitb', 'baseflow.deps.plfit', 'fit', 'nlinfit', ...
      'smoothdata', 'lsqnonlin', 'fminsearch'};
   for n = 1:numel(names)
      key = matlab.lang.makeValidName(names{n});
      R.paths.(key) = which(names{n}, '-all');
   end

   % Use the test's constants and the same public option builders.
   A = TestBaseflow.A;
   Dd = TestBaseflow.Dd;
   D = TestBaseflow.D;
   L = A * Dd / 1000;
   eventopts = baseflow.setopts('getevents', 'asannual', true);
   fitopts = baseflow.setopts('fitevents');
   opts = baseflow.setopts('globalfit', 'drainagearea', A, ...
      'aquiferdepth', D, 'streamlength', L, 'drainagedensity', Dd, ...
      'bootfit', false, 'plotfits', false);
   R.options = struct('events', eventopts, 'fits', fitopts, 'global', opts);
   [T, Q, rain] = baseflow.loadExampleData('kuparuk');
   R.in = struct('T', arrayhash(T), ...
      'Q', arrayhash(Q), ...
      'R', arrayhash(rain));

   % Retain stage outputs so comparisons can locate the first difference.
   Events = baseflow.wrapevents(T, Q, rain, eventopts);
   R.events = structhash(Events);
   R.eventCount = numel(unique(Events.eventTags(~isnan(Events.eventTags))));
   [Fits, K] = baseflow.fitevents(Events, fitopts);
   R.fits = structhash(Fits);
   R.K = structhash(K);
   R.fitCount = nnz(isfinite(K.a));
   G = baseflow.globalfit(K, Events, Fits, opts);
   [tau, q, dqdt, tags] = baseflow.eventtau(K, Events, Fits, ...
      'usefits', false);
   R.tau = struct('n', numel(tau), 'nfinite', nnz(isfinite(tau)), ...
      'hash', arrayhash(tau), 'tagshash', arrayhash(tags));
   R.result = struct('b', G.b, 'alpha', G.alpha, 'xmin', G.tau0, ...
      'expected', TestBaseflow.kuparukb, 'tolerance', TestBaseflow.btol, ...
      'absoluteError', abs(G.b - TestBaseflow.kuparukb), ...
      'productCheckPassed', abs(G.b - TestBaseflow.kuparukb) <= ...
      TestBaseflow.btol);
   R.rngAfter = rng;
   R.rngUnchanged = isequal(R.rngBefore, R.rngAfter);

   % Numeric time copies permit comparison without MATLAB object decoding.
   inputTime = T;
   eventTime = Events.eventTime;
   if isdatetime(eventTime)
      eventTime = convertTo(eventTime, 'datenum');
   end
   save(fullfile(outdir, 'kuparuk-stages.mat'), 'R', 'T', 'Q', 'rain', ...
      'inputTime', 'eventTime', 'Events', 'Fits', 'K', 'G', 'tau', 'q', ...
      'dqdt', 'tags', 'eventopts', 'fitopts', 'opts', '-v7');
   fid = fopen(fullfile(outdir, 'kuparuk-summary.json'), 'w');
   assert(fid >= 0, 'Cannot open the diagnostic summary.');
   filecleanup = onCleanup(@() fclose(fid));
   fprintf(fid, '%s', jsonencode(R, 'PrettyPrint', true));
   clear filecleanup
   fprintf('Captured %d events, %d fits, %d tau values; b=%.15f\n', ...
      R.eventCount, R.fitCount, numel(tau), G.b);
   fprintf('Product expectation check: %d (capture completion only).\n', ...
      R.result.productCheckPassed);
   clear cleanup
end

function h = arrayhash(values)
   %ARRAYHASH Match the retained diagnostic's double-array byte identity.
   md = java.security.MessageDigest.getInstance('SHA-256');
   md.update(typecast(double(values(:)), 'uint8'));
   h = sprintf('%02x', typecast(md.digest(), 'uint8'));
end

function result = structhash(values)
   %STRUCTHASH Preserve shapes and hashes for numeric stage fields.
   result = struct();
   names = fieldnames(values);
   for n = 1:numel(names)
      value = values.(names{n});
      if isdatetime(value)
         value = convertTo(value, 'datenum');
      end
      if isnumeric(value) || islogical(value)
         result.(names{n}) = sprintf('%s %s', ...
            mat2str(size(value)), arrayhash(value));
      end
   end
end

function restorestate(oldpath, olddir, oldrng, oldfigs)
   %RESTORESTATE Restore saved state and close figures opened by this call.
   close(setdiff(findall(groot, 'Type', 'figure'), oldfigs));
   rng(oldrng);
   path(oldpath);
   cd(olddir);
end
