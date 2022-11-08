
% script to publish gettingStarted.m as index.html on GitPages. 
cd ../demos
options = struct('format','html','outputDir','../docs/');
htmlDoc = publish('bfra_gettingStarted.m',options);
movefile(htmlDoc,'../docs/index.html')