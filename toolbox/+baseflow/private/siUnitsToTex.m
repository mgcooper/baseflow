function tex_labels = siUnitsToTex(units)
   % siUnitsToTex Convert SI units to TeX or LaTeX-formatted strings.
   %
   % Inputs:
   %   units: A cellstr array or string array containing standard SI units in
   %   the format 'm2 s-1' for meters squared per second, '-' for unitless, 'km
   %   s-1' for kilometers per second, etc. 
   %
   % Outputs:
   %   tex_labels: A cellstr array or string array containing TeX or
   %   LaTeX-formatted strings for use as labels in plots.
   %
   % See also: latex2tex

   % Ensure input is a cellstr array if it is a string array
   if isstring(units)
      units = cellstr(units);
   end

   % Preallocate the output cell array
   tex_labels = cell(size(units));

   % Process each input unit
   for i = 1:numel(units)
      unit = units{i};

      % Handle the unitless case
      if strcmp(unit, '-')
         tex_labels{i} = '-';
         continue
      end

      % Replace spaces with '\cdot' for TeX multiplication
      % unit = strrep(unit, ' ', ' \cdot ');

      % Replace positive and negative powers with LaTeX-style exponents.
      % Match the optional minus sign in the same pass so that each exponent
      % gets one pair of braces.
      unit = regexprep(unit, '(-?\d+)', '^{$1}');

      if isoctave
         tex_labels{i} = unit;
      else
         % Convert the unit to TeX format
         tex_labels{i} = texlabel(unit);
      end
   end

   % Replace '\{cdot}' with '\cdot' for proper TeX syntax
   tex_labels = cellfun(@(x) strrep(x,'\{cdot}','\cdot'), tex_labels, 'Uni', 0);

   % This doesn't work b/c texlabel doesn't add the {} around the entire
   % exponent
   % units = cellfun(@(x) strrep(x,'-','^-'),units,'UniformOutput',false);

end
