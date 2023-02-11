function OUT = getFeatureName(fullname)
% getFeatureName - translates a toolbox name from 'ver' into
% a feature name and vice versa, also checks license availability
%
% Syntax:
%   getFeatureName(fullname)
%
% Inputs:
%   fullname:       character vector of toolbox name as listed in ver
%                   output (optional, if none given all features are
%                   listed)
%
% Outputs:
%   translation:    cell array with clear name, feature name and license
%                   availability
%
%-------------------------------------------------------------------------
% Version 1.1
% 2018.09.04        Julian Hapke
% 2020.05.05        checks all features known to current release
%-------------------------------------------------------------------------
assert(nargin < 2, 'Too many input arguments')
% defaults
checkAll = true;
installedOnly = false;
if nargin
  checkAll = false;
  installedOnly = strcmp(fullname, '-installed');
end
if checkAll || installedOnly
    allToolboxes = com.mathworks.product.util.ProductIdentifier.values;
    nToolboxes = numel(allToolboxes);
    out = cell(nToolboxes, 3);
    for iToolbox = 1:nToolboxes
      marketingName = char(allToolboxes(iToolbox).getName());
      flexName = char(allToolboxes(iToolbox).getFlexName());
      out{iToolbox, 1} = marketingName;
      out{iToolbox, 2} = flexName;
      out{iToolbox, 3} = license('test', flexName);
    end
    if installedOnly
      installedToolboxes = ver;
      installedToolboxes = {installedToolboxes.Name}';
      out = out(ismember(out(:,1), installedToolboxes),:);
    end
    if nargout
        OUT = out;
    else
        out = [{'Name', 'FlexLM Name', 'License Available'}; out];
        disp(out)
    end
else
    productidentifier = com.mathworks.product.util.ProductIdentifier.get(fullname);
    if (isempty(productidentifier))
        warning('"%s" not found.', fullname)
        OUT = cell(1,3);
        return
    end
    feature = char(productidentifier.getFlexName());
    OUT = [{char(productidentifier.getName())} {feature} {license('test', feature)}];
end