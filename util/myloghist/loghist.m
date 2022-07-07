function [h,edges,centers,hfit] = loghist(data,varargin)

   p                 = inputParser;
   p.FunctionName    = 'loghist';
   p.CaseSensitive   = false;
   p.KeepUnmatched   = true;
   
   addRequired(p,'data',@(x)isnumeric(x));
   addParameter(p,'normalization','pdf',@(x)ischar(x));
   addParameter(p,'logmodel','loglog',@(x)ischar(x));
   addParameter(p,'edges',logbinedges(data),@(x)isnumeric(x));
   addParameter(p,'centers',logbincenters(data),@(x)isnumeric(x));
   addParameter(p,'dist','none',@(x)ischar(x));
   addParameter(p,'theta',0,@(x)isnumeric(x));
   
   parse(p,data,varargin{:});
   
   normalization  = string(p.Results.normalization);
   logmodel       = p.Results.logmodel;
   edges          = p.Results.edges;
   centers        = p.Results.centers;
   dist           = string(p.Results.dist);
   theta          = p.Results.theta;
   
   varargs        = unmatched2varargin(p.Unmatched);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   if normalization == "ccdf"; normalization = "survivor"; end

   if normalization == "survivor"
      
      % this is sufficient to make the plot
      [f,x] = ecdf(data,'Function','survivor');
      h     = stairs(x,f,'LineWidth',1.5);
      
%       % what i would need to do is map the 'centers' onto 'x', then pass
%       % those into ecdfhist, whihc should be possible using f,x recall that
%       % 'f' is the ecdf at each 'x', so i should be able to go from 'x' to
%       % 'centers', then get 'f' at the centers, and get n from that
%       
%       % this tries to coax the f,x into bins for histogram 
%       % this doesn't work b/c centers aren't the centers of 'x'
%       n     = ecdfhist(f,x,numel(edges)-1); % counts per bin
%       h     = histogram('BinEdges',edges,'BinCounts',n);
%       
%       % 
%       figure; ecdfhist(f,x,centers); % ,normalization,varargs{:});
      
   else
      h  = histogram(data,edges,'Normalization',normalization,varargs{:});
   end
   
   % fit a dist if requested
   if dist ~= "none"
      if dist == "GeneralizedPareto"
         % if gp distfit is requested, truncate the data for fitting
         dfit  = fitdist(data(data>theta),'GeneralizedPareto','Theta',theta);
      else
         dfit  = fitdist(data,dist); % see distfit for options I could add
      end
      
      % truncate the bins to the data range, so the plot is compact
      imax     = find(edges>=max(data),1,'first');
      imin     = find(edges>theta,1,'first');
      edges    = [max(theta,min(data)) edges(imin:imax)];
      centers  = edges(1:end-1)+diff(edges)./2;
      
%       % if gp is requested, make sure the bin centers/edges are >theta
%       if dist == "GeneralizedPareto"
%          edges    = [theta edges(edges>theta)];
%          centers  = edges(1:end-1)+diff(edges)./2;
%       end
         
      hold on; 
      switch normalization
         case 'pdf'
            pfit = dfit.pdf(centers);
%             refv = dfit.pdf(data(find(data>=theta,1,'first')));
%             pfit = refv.*pfit;
            hfit = plot(centers,pfit,'LineWidth',2.5,'LineStyle','-');
         case 'cdf'
            pfit = dfit.cdf(centers);
            refv = dfit.cdf(data(find(data>=theta,1,'first')));
            pfit = refv.*pfit;
            hfit = plot(centers,pfit,'LineWidth',1.5,'LineStyle','-');
         case 'survivor'
            hfit = plot(centers,dfit.cdf(centers,'upper'),'LineWidth',1.5,'LineStyle','--');
         otherwise
            error('no option to plot distfit using requested normalization');
      end
            
   end
   
   axis tight; hold off;
   
   % 
   switch logmodel
      
      case 'loglog'
         set(gca,'XScale','log','YScale','log');
         
      case 'semilogy'
         set(gca,'XScale','linear','YScale','log');
         
      case 'semilogx'
         set(gca,'XScale','log','YScale','linear');
   end
   
end

function edges = logbinedges(data)
   edges    = logspace(fix(log10(min(data))),ceil(log10(max(data))));
end

function centers = logbincenters(data)
   edges    = logbinedges(data);
   centers  = edges(1:end-1)+diff(edges)./2;
end
         