function h = xylabel(xlab,ylab,varargin)
%XYLABEL wrapper to plot both labels with one command

h(1) = xlabel(xlab,varargin{:});
h(2) = ylabel(ylab,varargin{:});

