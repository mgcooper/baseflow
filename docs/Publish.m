
% script to publish bfra_gettingStarted.m as index.html on GitPages. 
options = struct('format','html','outputDir','html/','useNewFigure',false);

publish('bfra_welcome.m',options);
publish('bfra_gettingStarted.m',options);
publish('bfra_demo.m',options);
publish('bfra_contents.m',options);

% this will be used in github actions 
% htmlDoc = publish('bfra_demo.m',options);
% htmlDoc = publish('bfra_gettingStarted.m',options);
% movefile(htmlDoc,'../docs/bfra_demo.html')
% movefile(htmlDoc,'../docs/gettingStarted.html')




