function texString = latex2tex(latexString)
   %LATEX2TEX Convert a LaTeX format string to a TeX interpreter format.
   %
   % latex2tex(latexString) takes a string in LaTeX format and converts it
   % into a format that will render correctly when using MATLAB's 'Interpreter',
   % 'tex'. It removes specific LaTeX-only commands, converts special characters
   % to their TeX equivalents, and performs other transformations as needed.
   %
   % Example:
   %   str = '$\mathrm{sin}(x) \ge 0$';
   %   newStr = latex2tex(str);
   %   % newStr would be 'sin(x) \geq 0'
   %
   % See also: untexlabel

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

   % Handle commands with no TeX equivalents
   texString = regexprep(texString, '\\textbf{([^}]*)}', '$1');
   texString = regexprep(texString, '\\textit{([^}]*)}', '$1');

   % Handle special characters
   texString = strrep(texString, '%', '\%');
   texString = strrep(texString, '&', '\&');
   texString = strrep(texString, '#', '\#');

   % Keep underscores so they render what follows as subscript.
   % To escape them, see untexlabel.m
   % texString = strrep(texString, '_', '\_');

   % Additional characters to escape
   % texString = strrep(texString, '{', '\{');
   % texString = strrep(texString, '}', '\}');
end
