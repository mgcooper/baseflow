function tf = isoctave()
tf = exist('OCTAVE_VERSION', 'builtin') ~= 0;