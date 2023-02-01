function Publish()
% script to publish bfra_gettingStarted.m as index.html on GitPages. 
options = struct('format','html','outputDir','html/','useNewFigure',false);

publish('bfra_welcome.m',options);
publish('bfra_gettingStarted.m',options);
publish('bfra_demo.m',options);
publish('bfra_contents.m',options);

% for github actions the landing page must be saved as index.html
copyfile('html/bfra_gettingStarted.html','index.html');

% not sure if other files can also be supported, if so:
% copyfile('html/bfra_demo.html','bfra_demo.html');





