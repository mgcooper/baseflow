function [Calm,Meta] = bfra_loadcalm(basinname)
%BFRA_LOADCALM loads calm ALT data for a basin in the Bounds struct

% since I think in terms of basins right now, not calm sites, this accepts
% the basin name not the calm site name

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   p                = MipInputParser;
   p.FunctionName   = 'bfra_loadcalm';
   p.addRequired('basinname',@(x)ischar(x));
   p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
   MetaBasin   =  bfra_loadmeta(basinname);

   % load the calm data
   pathdata    =  setpath('/interface/data/permafrost/');
   filedata    =  [pathdata 'CALM_ALT.mat'];
   
   load(filedata,'Calm','Meta'); MetaCalm = Meta; clear Meta;
   
   % find the calm data
   if MetaBasin.num_calm == 0
      error('no calm data for this basin')
   else
      % the indices of the calm sites for this basin
      idx   =  MetaBasin.idx_calm{:};
      Calm  =  Calm(:,idx);
      Meta  =  MetaCalm(idx,:);
      
%       % for the case of multiple sites, need to choose what to do
%       if numel(idx)>1
%          [Calm,Meta] = aggregateCalmData(Calm,Meta);
%       end
      
      % on second thought, I think we want to just return all the data and
      % deal with it on a case-by-case basis, fitting trends to all sites
      % with sufficient data, then average the trends rather than averaging
      % across sites here
      % i think we want this:
      % 1. synchronize all the sites
      % 2. eliminate sites with <10 years of data
      % 3. 

   end
   
end

% function [Calm,Meta] = aggregateCalmData(Calm,Meta)
%    
%    % this stuff could be moved to bfra_loadcalm
%    % this converts all the site data into one timeseries with stats
%    Data     = timetablereduce(Data);
% 
%    macfig; 
%    trendplot(Data.Time,Data.mu,'useax',gca,'errorbars',true,'yerr',Data.sigma);
% 
%    % make a shapefile
%    [SE,CI,PM,mu,sigma] = stderr(transpose(table2array(Data)));
% 
%    S        = MetaCalm(Points.inpolyb,:);
%    S.avg    = mu;
%    S.std    = sigma;
%    S        = table2struct(tablecategorical2char(S));
%    S        = renameStructFields(S,{'LAT','LON'},{'Lat','Lon'});
%    S        = geopoint(S);
% 
% % %    this was here as an example of how i might write a function
% % bfra_writeshapefile
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% % save the data
% %~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%    if saveshp == true
%       fsave    = [pathshp 'kuparuk_CALM.shp'];
%       writeGeoShapefile(S,fsave);
%    end
%    
% end
