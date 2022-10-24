
clean
savedata = false;

% this loads and saves the two sources of precipitation data

basinname = bfra_basinname('KUPARUK R NR DEADHORSE AK');
t1 = datetime(1983,1,1);
t2 = datetime(2020,12,31);

% load and save the COOP (GHCND) station data:
R = bfra_loadghcnd(basinname,'t1',t1,'t2',t2); 
T = R.Time;
R = R.PRCP;

if savedata == true
   save('data/ppt/ppt_coop.mat','R','T');
end


% load and save the LTER station data:
R = load('kuparukRainDataLTER.mat'); R = R.Data;
R = retime(R,T,'fillwithmissing');
R = R.rain;

if savedata == true
   save('data/ppt/ppt_lter.mat','R','T');
end

% combine the two
load('data/ppt/ppt_coop.mat','R'); R1 = R;
load('data/ppt/ppt_lter.mat','R'); R2 = R;
R = sum([R1 R2],2,'omitnan'); % sum across the 2nd dim 

if savedata == true
   save('data/ppt/ppt_both.mat','R','T');
end

