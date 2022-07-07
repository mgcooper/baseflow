function opts = bfra_defaultopts(type)
%BFRA_DEFAULTOPTS set default algo options
   
% default bfra settings
switch type
   
   case 'events'   
      
      opts.qmin         = 1;        % minimum flow amount (m3/d)
      opts.nmin         = 4;        % minimum number of flow values
      opts.fmax         = 1;        % maximum fillable missing values
      opts.rmax         = 2;        % maximum allowable consecutive values
      opts.rmin         = 0;        % maximum allowable rainfall in mm
      opts.cmax         = 2;        % consecutive convex points
      opts.rmnochange   = true;     % remove constant (no change) values?
      opts.rmconvex     = false;    % remove convex derivatives?
      opts.rmrain       = true;     % remove data on days with recorded rain?
      opts.pickevents   = false;    % pick events manually? 
      opts.plotevents   = false;    % plot the detected events?
      
   case 'fits'
      
      opts.pickfits     = false;    % pick fits manually?
      opts.pickmethod   = 'none';   % method to fit picks manually
      opts.plotfits     = false;    % plot the fits? 
      opts.savefitplots = false;    % save plots of fits? 
      opts.derivmethod  = 'ETS';    % derivative (dQ/dt) method
      opts.fitmethod    = 'nls';    % fitting method
      opts.fitorder     = 'free';   % fitting order
      opts.fitnmin      = 4;        % min required values to fit ETS      
      opts.etsparam     = 0.2;      % min flow length parameter
      opts.drainagearea = nan;      % drainage area in m2
      opts.gageID       = 'none';   % station name or ID
end


