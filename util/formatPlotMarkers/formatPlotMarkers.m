function h = formatPlotMarkers(varargin)
%formatPlotMarkers applies custom formatting to plot markers to avoid
%cluttering up code. optional syntax: formatPlotMarkers('sparsefill',true)
%only fills ten markers e.g. if you plot data with a small spacing between
%points, you can have a continuous line with a filled marker every few
%points. To control the number of points, try:
%formatPlotMarkers('sparsefill',true,numPoints). To control the axis to
%which the formatting is applied: scatterfill('suppliedaxis',axobj) where
%axobj is a matlab.graphics.axis.Axes object. To control the specific line
%to which the formatting is applied,: scatterfill('suppliedaxis',lineobj)
%where lineobj is a handle to a plotted line. Note, the function checks in
%lineobj is in fact an axis and if so, 

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   p               = inputParser;
   p.FunctionName  = 'formatPlotMarkers';
   p.CaseSensitive = false;
   p.KeepUnmatched = true;

  %addParameter(  p,'markerfacecolor', 'none',        @(x)ischar(x)     );
   addParameter(  p,'fillspacing',     nan,           @(x)isscalar(x)   );
   addParameter(  p,'sparsefill',      false,         @(x)islogical(x)  );
   addParameter(  p,'markersize',      10,            @(x)isnumeric(x)  );
   addParameter(  p,'suppliedaxes',    gca,           @(x)any(isaxis(x)));
   addParameter(  p,'suppliedline',    nan,           @(x)isobject(x)   );
  
   

   parse(p,varargin{:});

  %markerfacecolor   = rbg(p.Results.markerfacecolor);
   fillspacing    = p.Results.fillspacing;
   sparsefill     = p.Results.sparsefill;
   markersize     = p.Results.markersize;
   suppliedaxes   = p.Results.suppliedaxes;
   suppliedline   = p.Results.suppliedline;
   unmatched      = p.Unmatched;
   
   % convert unmatched to varargin
   varargs        = unmatched2varargin(unmatched);
      
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~   
   
% %  rather than isobject, I could use this to check the line input handle:
%    if isa(suppliedline,'matlab.graphics.chart.primitive.Line')
%    end

   % set sparsefill true if fillspacing has a value to simplify the code.
   % this way either can be passed in, fillspacing, or sparsefill, where
   % sparsefill automatically fills every ten points.
   if ~isnan(fillspacing)
      sparsefill = true;
      if ischar(fillspacing)
         % just in case a string is somehow passed in by mistake
         fillspacing = str2double(fillspacing);
      end
   end
   
   numaxes              = numel(suppliedaxes);
   numlineswithmarkers  = 0; 
   
for m = 1:numaxes

   if numaxes == 1
      suppliedaxis = suppliedaxes;
   else
      suppliedaxis = suppliedaxes(m);
   end

   % use the supplied axis unless a specific line was supplied
   if ~isobject(suppliedline) && isnan(suppliedline)
      % there is either a supplied axis, or we assigned gca to it
      Children = allchild(suppliedaxis);  % get the children to find lines
   else
      Children = suppliedline;
   end

   % this should work for cases where Children comes up empty. EDIT,
   % previously I did not loop through Children. In simple cases, all the
   % lines with markers on an axis will be found, but in some cases, such
   % as with lsline, try will fail, and no lines with markers will be
   % found, so we loop through all the children and get ones with markers
   numchildren       = numel(Children);
   linesWithMarkers  = false(numchildren);
   for mm = 1:numchildren
      child    = Children(mm);
      
      % I think this is here in case a child has more than one line, but if
      % only one line per child, it would be sufficient to store the
      % true-false in linehasmarkers instead of the any() statement after
      % the try-catch
      try
         linehasmarkers    = ~ismember({child.Marker},'none');
      catch
         linehasmarkers    = false(size({child.Marker}));
      end
      
      % I replaced the child(linehasmarkers) with the true-false, so now
      % linesWithMarkers is a tf in the loop, and after the loop it becomes
      % a container for the lines with markers
      linesWithMarkers(mm) = any(linehasmarkers);
%       linesWithMarkers     = child(linehasmarkers);
      numlineswithmarkers  = numlineswithmarkers + sum(linehasmarkers);
   end
   
   linesWithMarkers  = Children(linesWithMarkers);
   
   if isempty(linesWithMarkers)
      continue;
   end
      
   
   for n = 1:numel(linesWithMarkers)
      
      thisLine    = linesWithMarkers(n);
      
      if isa(thisLine,'matlab.graphics.chart.primitive.Scatter')
         continue
      end
      
      numPoints   = numel(thisLine.XData);
      
      if sparsefill == true
      % only fill some points, use larger symbol size
      
         % if not provided, set fillspacing such that 10 points are filled
         if isnan(fillspacing)
            fillspacing = max(1,numPoints/10); % if <10 points fill them all
         end
         numfill     = fix(numPoints/fillspacing);
         markerIdx   = round(linspace(1,numPoints,numfill),0);
      else
      % fill all points, use smaller symbol size
         markerIdx   = 1:numPoints;
         markerSz    = 6;
      end
      markerColor = thisLine.Color;
      %         markerColor = thisLine.MarkerEdgeColor;
      
      % errorbar doesn't have 'MarkerIndices'
      if iserrorbar(thisLine)
         set(thisLine,     'MarkerSize',           markersize,       ...
                           'Color',                markerColor,      ...
                           'MarkerEdgeColor',      [.3 .3 .3],       ...
                           'MarkerFaceColor',      markerColor,      ...
                           'CapSize',              0,                ...
                           varargs{:}                              );
      else
         set(thisLine,     'MarkerIndices',        markerIdx,        ...
                           'MarkerSize',           markersize,       ...
                           'MarkerEdgeColor',      'none',           ...
                           'MarkerFaceColor',      markerColor,      ...
                           varargs{:}                              );
      end
      
   end

end

if numlineswithmarkers == 0
   h = [];
   disp('no lines with markers found')
   return;
end
   
   % for reference, could use these to validate suppliedline
   % if isa(linesWithMarkers,'matlab.graphics.primitive.Line.Type')
   
   % but there are others, and I am not sure of them all:
   % if isa(linesWithMarkers,'matlab.graphics.chart.primitive.Line.Type')
   % if isa(linesWithMarkers,'matlab.graphics.function.FunctionLine.Type')
   % if isa(linesWithMarkers,'matlab.graphics.function.ImplicitFunctionLine.Type')
   % if isa(linesWithMarkers,'matlab.graphics.function.ParameterizedFunctionLine.Type')
   % if isa(linesWithMarkers,'matlab.graphics.chart.decoration.ConstantLine.Type')

end


%    scatterfill     = true;
%    if nargin == 1
%       %Children    = varargin{1};  % plot handles (not axis)
%       scatterfill  = varargin{1};  % true means fill every point
%    else
%       ax          = gca;
%       Children    = allchild(ax);
%    end
%    
%    % this should work for cases where Children comes up empty
%    try
%       linesWithMarkers    = Children(~ismember({Children.Marker},'none'));
%    catch
%       h = [];
%       return;
%    end
%    
%    for n = 1:numel(linesWithMarkers)
%       
%       thisLine    = linesWithMarkers(n);
%       numPoints   = numel(thisLine.XData);
%       
%       if scatterfill == true
%          markerIdx   = 1:numPoints;
%          markerSz    = 6;
%       else
%          markerIdx = round(linspace(1,numPoints,10),0);
%          markerSz    = 8;
%       end
%       markerColor = thisLine.Color;
%       %         markerColor = thisLine.MarkerEdgeColor;
%       
%       set(thisLine,   'MarkerIndices',        markerIdx,      ...
%          'MarkerSize',           markerSz,       ...
%          'MarkerEdgeColor',      'none',         ...
%          'MarkerFaceColor',      markerColor,    ...
%          varargin{:});
%    end
% end

%    validQ         = @(x)validateattributes(x,{'numeric'},               ...
%                         {'real','column','size',size(T)},               ...
%                         'BFRA_dQdt','Q',1);
%    validTime      = @(x)validateattributes(x,{'numeric'},               ...
%                         {'real','column','size',size(Q)},               ...
%                         'BFRA_dQdt','T',2);
%    validDeriv     = @(x)validateattributes(x,{'char','string'},         ...
%                         {'scalartext'},                                 ...
%                         'BFRA_dQdt','deriv',3);
%    validWindow    = @(x)validateattributes(x,{'numeric'},               ...
%                         {'real','scalar'},                              ...
%                         'BFRA_dQdt','window');
%    validfitMethod = @(x)validateattributes(x,{'char','string'},         ...
%                         {'scalartext'},                                 ...
%                         'BFRA_dQdt','fitmethod');
%    validpickMethod= @(x)validateattributes(x,{'char','string'},         ...
%                         {'scalartext'},                                 ...
%                         'BFRA_dQdt','pickmethod');
%    addRequired(   p,'Q',                           validQ            );
%    addRequired(   p,'T',                           validTime         );
%    addRequired(   p,'deriv',                       validDeriv        );
