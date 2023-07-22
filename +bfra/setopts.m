function opts = setopts(funcname,varargin)
%SETOPTS set algorithm options for functions getevents, fitevents, and globalfit
%
%  Required inputs
%
%     funcname    : 'getevents', 'fitevents', or 'globalfit'
%
%     indicates whether to send back the default options for the event detection
%     algorithm 'getevents', the event fitting algorithm 'fitdqdt', or the
%     global fitting algorithm 'globalfit'
%
%  Optional name-value inputs for type 'getevents'
%
%     opts        :  structure containing any of the following fields
%
%     qmin        :  minimum flow value, below which values are set nan (m3/d)
%     nmin        :  minimum event length
%     fmax        :  maximum # of missing values gap-filled
%     rmax        :  maximum runlength of sequential constant values
%     rmin        :  maximum allowable rainfall in mm/d 
%     cmax        :  maximum run of sequential convex dQ/dt values
%     rmconvex    :  remove convex derivatives
%     rmnochange  :  remove consecutive constant derivates
%     rmrain      :  remove data on days with rainfall>rmin
%     pickevents  :  option to manually pick events
%     plotevents  :  option to plot picked events
%     asannual    :  option to detect events on an annual basis
%
%  Optional name-value inputs for type 'fitevents'
% 
%     derivmethod    : derivative (dQ/dt) method
%     fitmethod      : -dQ/dt = aQb fitting method
%     fitorder       : fitting order (value of exponent b)
%     fitnmin        : minimum number of values required to fit -dQ/dt = aQb 
%     pickfits       : pick fits manually?
%     pickmethod     : method to fit picks manually
%     plotfits       : plot the fits?
%     savefitplots   : save plots of fits?
%     etsparam       : min flow length parameter for ETS algorithm
%     vtsparam       : min flow length parameter for VTS algorithm
%     drainagearea   : drainage area in m2
%     gageID         : station name or ID
% 
%  Optional name-value inputs for type 'globalfit'
% 
%     drainagearea   : drainage area [m2]
%     drainagedens   : drainage density [km-1] = streamlength/drainagearea
%     aquiferdepth   : reference aquifer thickness [m]
%     streamlength   : effective channel length [m]
%     aquiferslope   : effective aquifer slope
%     aquiferbreadth : distance from channel to divide
%     drainableporos : drainable porosity
%     isflat         : logical indicating true or false
%     plotfits       : plot the various global fits?e
%     bootfit        : logical indicating whether to bootstrap the uncertainites
%     nreps          : number of reps for bootstrapping 
%     phimethod      : method used to fit drainable porosity
%     refqtls        : quantiles of Q and -dQ/dt for early/late reference lines
%     earlyqtls      : quantiles of Q and -dQ/dt for early reference lines
%     lateqtls       : quantiles of Q and -dQ/dt for late reference lines
%
%  See also getfits, fitdqdt
%
%  Matt Cooper, 22-Oct-2022, https://github.com/mgcooper

% if called with no input, open this file
if nargin == 0; open(mfilename('fullpath')); return; end

%% set default bfra settings

import bfra.validation.*

p = inputParser;
p.FunctionName = 'bfra.setopts';

p.addRequired('funcname', @ischar);
parse(p,funcname);

switch funcname

   % event detection - input options for getevents
   case 'getevents'

      addParameter(p,   'qmin',        1,          @isnumericscalar );
      addParameter(p,   'nmin',        4,          @isnumericscalar );
      addParameter(p,   'fmax',        1,          @isnumericscalar );
      addParameter(p,   'rmax',        2,          @isnumericscalar );
      addParameter(p,   'rmin',        1,          @isnumericscalar );
      addParameter(p,   'cmax',        2,          @isnumericscalar );
      addParameter(p,   'rmconvex',    false,      @islogicalscalar );
      addParameter(p,   'rmnochange',  true,       @islogicalscalar );
      addParameter(p,   'rmrain',      true,       @islogicalscalar );
      addParameter(p,   'pickevents',  false,      @islogicalscalar );
      addParameter(p,   'plotevents',  false,      @islogicalscalar );
      addParameter(p,   'asannual',    false,      @islogicalscalar );

   % event fits - input options for fitevents
   case 'fitevents'

      addParameter(p,   'derivmethod', 'ETS',      @ischar           );
      addParameter(p,   'fitmethod',   'nls',      @ischar           );
      addParameter(p,   'fitorder',    nan,        @isnumericscalar  );
      addParameter(p,   'pickfits',    false,      @islogicalscalar  );
      addParameter(p,   'pickmethod',  'none',     @ischar           );
      addParameter(p,   'plotfits',    false,      @islogicalscalar  );
      addParameter(p,   'saveplots',   false,      @islogicalscalar  );
      addParameter(p,   'etsparam',    0.2,        @isnumericscalar  );
      addParameter(p,   'vtsparam',    1.0,        @isnumericscalar  );
      
   % global fit - input to bfra.globalfit
   case 'globalfit'

      addParameter(p,   'drainagearea',   nan,           @isnumericscalar );
      addParameter(p,   'drainagedens',   0.8,           @isnumericscalar );
      addParameter(p,   'aquiferdepth',   nan,           @isnumericscalar );
      addParameter(p,   'streamlength',   nan,           @isnumericscalar );
      addParameter(p,   'aquiferslope',   0.0,           @isnumericscalar );
      addParameter(p,   'aquiferbreadth', nan,           @isnumericscalar );
      addParameter(p,   'drainableporos', 0.1,           @isnumericscalar );
      addParameter(p,   'isflat',         true,          @islogicalscalar );
      addParameter(p,   'plotfits',       false,         @islogicalscalar );
      addParameter(p,   'bootfit',        false,         @islogicalscalar );
      addParameter(p,   'nreps',          1000,          @isnumericscalar );
      addParameter(p,   'phimethod',      'pointcloud',  @ischar           );
      addParameter(p,   'refqtls',        [0.50 0.50],   @isnumericvector );
      addParameter(p,   'earlyqtls',      [0.95 0.95],   @isnumericvector );
      addParameter(p,   'lateqtls',       [0.50 0.50],   @isnumericvector );

end

parse(p,funcname,varargin{:});

opts = p.Results;
opts = rmfield(opts,'funcname');

