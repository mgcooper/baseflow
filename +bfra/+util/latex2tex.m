function texString = latex2tex(latexString)
%LATEX2TEX 

% Initialize the TeX string as the LaTeX string
texString = latexString;

% Remove the $ symbols
texString = strrep(texString, '$', '');

% Replace LaTeX commands with their TeX equivalents. Add more as needed.
texString = strrep(texString, '\mathrm', '');
texString = strrep(texString, '\quad', ' ');
texString = strrep(texString, '\;', ' ');
texString = strrep(texString, '\ge', '\geq');
texString = strrep(texString, '\hat', '');

% Handle special characters
texString = strrep(texString, '%', '\%');
texString = strrep(texString, '&', '\&');
texString = strrep(texString, '#', '\#');
texString = strrep(texString, '_', '\_');

% texString = strrep(texString, '{', '\{');
% texString = strrep(texString, '}', '\}');
end
