function opts = setopts(type,varargin)
%SETOPTS sets default or custom bfra algorithm options for type 'events' or 'fits'
%
%  Required inputs
%
%     type        = 'events', 'fits', or 'globalfit'
%
%     indicates whether to send back the default options for the event detection
%     algorithm 'getevents', the event fitting algorithm 'fitdqdt', or the
%     global fitting algorithm 'globalfit'
%
%  Optional name-value inputs
%
%     opts        =  structure containing any of the following fields
%
%     qmin        =  minimum flow value, below which values are set nan
%     nmin        =  minimum event length
%     fmax        =  maximum # of missing values gap-filled
%     rmax        =  maximum run of sequential constant values
%     rmin        =  minimum rainfall required to censor flow (mm/day?)
%     cmax        =  maximum run of sequential convex dQ/dt values
%     rmconvex    =  remove convex derivatives
%     rmnochange  =  remove consecutive constant derivates
%     rmrain      =  remove rainfall
%     pickevents  =  option to manually pick events
%     plotevents  =  option to plot picked events
%
%
%  See also getfits, fitdqdt

%-------------------------------------------------------------------------------
% % set default bfra settings
%-------------------------------------------------------------------------------

p                 = inputParser;
p.FunctionName    = 'bfra.setopts';
% p.PartialMatching = true;
p.addRequired('type',@(x)ischar(x));
parse(p,type);

switch type

   % event detection - input options for getevents
   case 'events'

      addParameter(p,   'qmin',        0,          @(x) isnumericscalar(x)  );
      addParameter(p,   'nmin',        4,          @(x) isnumericscalar(x)  );
      addParameter(p,   'fmax',        1,          @(x) isnumericscalar(x)  );
      addParameter(p,   'rmax',        2,          @(x) isnumericscalar(x)  );
      addParameter(p,   'rmin',        0,          @(x) isnumericscalar(x)  );
      addParameter(p,   'cmax',        2,          @(x) isnumericscalar(x)  );
      addParameter(p,   'rmconvex',    false,      @(x) islogicalscalar(x)  );
      addParameter(p,   'rmnochange',  true,       @(x) islogicalscalar(x)  );
      addParameter(p,   'rmrain',      true,       @(x) islogicalscalar(x)  );
      addParameter(p,   'pickevents',  false,      @(x) islogicalscalar(x)  );
      addParameter(p,   'plotevents',  false,      @(x) islogicalscalar(x)  );

%       opts.qmin         = 0;        % minimum flow amount (m3/d)
%       opts.nmin         = 4;        % minimum number of flow values
%       opts.fmax         = 1;        % maximum fillable missing values
%       opts.rmax         = 2;        % maximum allowable consecutive values
%       opts.rmin         = 0;        % maximum allowable rainfall in mm
%       opts.cmax         = 2;        % consecutive convex points
%       opts.rmconvex     = false;    % remove convex derivatives?
%       opts.rmnochange   = true;     % remove constant (no change) values?
%       opts.rmrain       = true;     % remove data on days with recorded rain?
%       opts.pickevents   = false;    % pick events manually?
%       opts.plotevents   = false;    % plot the detected events?


   % event fits - input options for fitevents
   case 'fits'

      addParameter(p,   'derivmethod', 'ETS',      @(x) ischar(x)             );
      addParameter(p,   'fitmethod',   'nls',      @(x) ischar(x)             );
      addParameter(p,   'fitorder',    'free',     @(x) ischar(x)|isnumeric(x));
      addParameter(p,   'fitnmin',     4,          @(x) isnumericscalar(x)    );
      addParameter(p,   'pickfits',    false,      @(x) islogicalscalar(x)    );
      addParameter(p,   'pickmethod',  'none',     @(x) ischar(x)             );
      addParameter(p,   'plotfits',    false,      @(x) islogicalscalar(x)    );
      addParameter(p,   'savefitplots',false,      @(x) islogicalscalar(x)    );
      addParameter(p,   'etsparam',    0.2,        @(x) isnumericscalar(x)    );
      addParameter(p,   'vtsparam',    1.0,        @(x) isnumericscalar(x)    );
      addParameter(p,   'drainagearea',nan,        @(x) isnumericscalar(x)    );
      addParameter(p,   'gageID',      'none',     @(x) ischar(x)             );

%       opts.derivmethod  = 'ETS';    % derivative (dQ/dt) method
%       opts.fitmethod    = 'nls';    % fitting method
%       opts.fitorder     = 'free';   % fitting order
%       opts.fitnmin      = 4;        % min required values to fit ETS
%       opts.pickfits     = false;    % pick fits manually?
%       opts.pickmethod   = 'none';   % method to fit picks manually
%       opts.plotfits     = false;    % plot the fits?
%       opts.savefitplots = false;    % save plots of fits?
%       opts.etsparam     = 0.2;      % min flow length parameter
%       opts.vtsparam     = 1.0;      % min flow length parameter
%       opts.drainagearea = nan;      % drainage area in m2
%       opts.gageID       = 'none';   % station name or ID


   % global fit - input to bfra.globalfit
   case 'globalfit'

      addParameter(p,   'drainagearea',   nan,           @(x)isnumericscalar(x)  );
      addParameter(p,   'aquiferdepth',   nan,           @(x)isnumericscalar(x)  );
      addParameter(p,   'streamlength',   nan,           @(x)isnumericscalar(x)  );
      addParameter(p,   'aquiferslope',   nan,           @(x)isnumericscalar(x)  );
      addParameter(p,   'aquiferbreadth', nan,           @(x)isnumericscalar(x)  );
      addParameter(p,   'isflat',         true,          @(x)islogicalscalar(x)  );
      addParameter(p,   'plotfits',       false,         @(x)islogicalscalar(x)  );
      addParameter(p,   'bootfit',        false,         @(x)islogicalscalar(x)  );
      addParameter(p,   'nreps',          1000,          @(x)isdoublescalar(x)   );
      addParameter(p,   'phimethod',      'pointcloud',  @(x)ischar(x)           );
      addParameter(p,   'refqtls',        [0.50 0.50],   @(x)isnumericvector(x)  );
      addParameter(p,   'earlyqtls',      [0.90 0.90],   @(x)isnumericvector(x)  );
      addParameter(p,   'lateqtls',       [0.50 0.50],   @(x)isnumericvector(x)  );

%       opts.drainagearea    = nan;         % drainage area in m2
%       opts.aquiferdepth    = nan;         % reference aquifer thickness [m]
%       opts.streamlength    = nan;         %
%       opts.aquiferslope    = nan;         % aquifer slope
%       opts.aquiferbreadth  = nan;         % distance from channel to divide
%       opts.isflat          = true;        % logical indicating true or fals
%       opts.plotfits        = false;       % plot the various global fits?e
%       opts.bootfit         = false;
%       opts.nreps           = 1000;
%       opts.phimethod       = 'pointcloud';
%       opts.refqtls         = [0.50 0.50];
%       opts.earlyqtls       = [0.90 0.90];
%       opts.lateqtls        = [0.50 0.50];
end

parse(p,type,varargin{:});

opts = p.Results;
opts = rmfield(opts,'type');

