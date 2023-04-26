function h = formatPlotMarkers(varargin)
%FORMATPLOTMARKERS apply custom formatting to plot markers. provides a cleaner
%method to set aesthetically pleasing plot formatting without cluttering code.
% 
%  h = formatPlotMarkers() applies default formatting
% 
%  h = formatPlotMarkers('sparsefill',true) reduces the density of plotted
%  markers
% 
%optional syntax: formatPlotMarkers('sparsefill',true) only fills ten
%markers e.g. if you plot data with a small spacing between 
%points, you can have a continuous line with a filled marker every few
%points. To control the number of points, try:
%formatPlotMarkers('sparsefill',true,numPoints). To control the axis to
%which the formatting is applied: scatterfill('suppliedaxis',axobj) where
%axobj is a matlab.graphics.axis.Axes object. To control the specific line
%to which the formatting is applied,: scatterfill('suppliedaxis',lineobj)
%where lineobj is a handle to a plotted line. Note, the function checks in
%lineobj is in fact an axis and if so,

% --------------- parse inputs
p = inputParser;
p.FunctionName = mfilename;
p.CaseSensitive = false;
p.KeepUnmatched = true;

%addParameter( p,'markerfacecolor', 'none', @(x)ischar(x) );
addParameter( p,'sparsefill', false, @(x)islogical(x) );
addParameter( p,'markersize', 10, @(x)isnumeric(x) );
addParameter( p,'fillspacing', nan, @(x)isscalar(x) );
addParameter( p,'suppliedaxes', gca, @(x)any(bfra.validation.isaxis(x)));
addParameter( p,'suppliedline', nan, @(x)isobject(x) );

parse(p,varargin{:});

%markerfacecolor   = rbg(p.Results.markerfacecolor);
suppliedaxes = p.Results.suppliedaxes;
suppliedline = p.Results.suppliedline;
fillspacing = p.Results.fillspacing;
sparsefill = p.Results.sparsefill;
markersize = p.Results.markersize;
unmatched = p.Unmatched;

% convert unmatched to varargin
varargs = namedargs2cell(unmatched);

% --------------- code

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

numaxes = numel(suppliedaxes);
numlineswithmarkers = 0;

for m = 1:numaxes

   if numaxes == 1
      thisaxis = suppliedaxes;
   else
      thisaxis = suppliedaxes(m);
   end

   % use the supplied axis unless a specific line was supplied
   if ~isobject(suppliedline) && isnan(suppliedline)
      % there is either a supplied axis, or we assigned gca to it
      Children = allchild(thisaxis);  % get the children to find lines
   else
      Children = suppliedline;
   end

   % this should work for cases where Children comes up empty. EDIT,
   % previously I did not loop through Children. In simple cases, all the
   % lines with markers on an axis will be found, but in some cases, such
   % as with lsline, try will fail, and no lines with markers will be
   % found, so we loop through all the children and get ones with markers
   numchildren = numel(Children);
   linesWithMarkers = false(numchildren);
   for mm = 1:numchildren
      child = Children(mm);
      
      if child.Type == "bar" % add more types: || child.Type == ""
         % continue, leave linesWithMarkers(mm) = false;
         continue
      end

      % I think this is here in case a child has more than one line, but if
      % only one line per child, it would be sufficient to store the
      % true-false in linehasmarkers instead of the any() statement after
      % the try-catch
      try
         linehasmarkers = ~ismember({child.Marker},'none');
      catch
         try
            linehasmarkers = false(size({child.Marker}));
         catch % catch-all back up
            linehasmarkers = false;
         end
      end

      % I replaced the child(linehasmarkers) with the true-false, so now
      % linesWithMarkers is a tf in the loop, and after the loop it becomes
      % a container for the lines with markers
      linesWithMarkers(mm) = any(linehasmarkers);
      % linesWithMarkers = child(linehasmarkers);
      numlineswithmarkers = numlineswithmarkers + sum(linehasmarkers);
   end

   linesWithMarkers = Children(linesWithMarkers);

   if isempty(linesWithMarkers)
      continue
   end


   for n = 1:numel(linesWithMarkers)

      thisLine = linesWithMarkers(n);

      if isa(thisLine,'matlab.graphics.chart.primitive.Scatter')
         continue
      end

      numPoints = numel(thisLine.XData);

      if sparsefill == true
         % only fill some points, use larger symbol size

         % if not provided, set fillspacing such that 10 points are filled
         if isnan(fillspacing)
            fillspacing = max(1,numPoints/10); % if <10 points fill them all
         end
         numfill = fix(numPoints/fillspacing);
         markerIdx = round(linspace(1,numPoints,numfill),0);
      else
         % fill all points, use smaller symbol size
         markerIdx = 1:numPoints;
         markerSz = 6;
      end
      markerColor = thisLine.Color;
      %         markerColor = thisLine.MarkerEdgeColor;

      % errorbar doesn't have 'MarkerIndices'
      if bfra.validation.iserrorbar(thisLine)
         set(thisLine, ...
            'MarkerSize',           markersize,       ...
            'Color',                markerColor,      ...
            'MarkerEdgeColor',      [.3 .3 .3],       ...
            'MarkerFaceColor',      markerColor,      ...
            'CapSize',              0,                ...
            varargs{:}                                );
      else
         set(thisLine, ...
            'MarkerIndices',        markerIdx,        ...
            'MarkerSize',           markersize,       ...
            'MarkerEdgeColor',      'none',           ...
            'MarkerFaceColor',      markerColor,      ...
            varargs{:}                                );
      end

   end

end

if numlineswithmarkers == 0
   h = [];
   disp('no lines with markers found')
   return
end

% for reference, could use these to validate suppliedline
% if isa(linesWithMarkers,'matlab.graphics.primitive.Line.Type')

% but there are others, and I am not sure of them all:
% if isa(linesWithMarkers,'matlab.graphics.chart.primitive.Line.Type')
% if isa(linesWithMarkers,'matlab.graphics.function.FunctionLine.Type')
% if isa(linesWithMarkers,'matlab.graphics.function.ImplicitFunctionLine.Type')
% if isa(linesWithMarkers,'matlab.graphics.function.ParameterizedFunctionLine.Type')
% if isa(linesWithMarkers,'matlab.graphics.chart.decoration.ConstantLine.Type')