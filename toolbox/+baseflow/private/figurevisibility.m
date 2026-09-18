function visibility = figurevisibility(show)
   %FIGUREVISIBILITY Visibility of a figure a caller asked to show.
   %
   % Syntax
   %
   %     visibility = figurevisibility(show)
   %
   % Description
   %
   %     visibility = figurevisibility(show) returns 'on' when show is
   %     true and 'off' when it is false.
   %
   %     It returns 'off' whatever show says when the root asks for
   %     invisible figures, which baseflow.internal.runtests does for the
   %     length of a test run. The figure is still drawn, so a caller that
   %     reads it finds what it needs, and no window opens. A figure
   %     created with an explicit 'Visible' of 'on' ignores that root
   %     default, which is why this function reads it.
   %
   % See also: fitphidist, runtests

   % Octave has no root 'default' query, so take the request as given.
   if isoctave
      visibility = onoff(show);
      return
   end

   % get errors on a default the root never set, so ask which defaults
   % exist before reading this one.
   defaults = get(groot, 'default');
   if isfield(defaults, 'defaultFigureVisible') ...
         && strcmp(defaults.defaultFigureVisible, 'off')
      visibility = 'off';
      return
   end

   visibility = onoff(show);
end

function state = onoff(show)
   % Translate a true or false request to the char the Visible property
   % takes.
   if show
      state = 'on';
   else
      state = 'off';
   end
end
