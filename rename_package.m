
clean

cd('/Users/coop558/myprojects/matlab/bfra/+bfra/');

% list = getlist(pwd,'.m');
% 
% for n = 1:numel(list)
%    
%    oldname = list(n).name;
%    
%    if contains(oldname,'BFRA_')
%       
%       newname = strrep(oldname,'BFRA_','');
%       
%    elseif contains(oldname,'bfra_')
%       
%       newname = strrep(oldname,'bfra_','');
%    else
%       continue
%    end
%    
%    % rename the file
%    system(['git mv ' oldname ' ' newname])
%    
% end

% now open all the files and remove the bfra_ from the function name

list = getlist(pwd,'.m');

for n = 1:numel(list)
   
   fname       = list(n).name;
   fid         = fopen(list(n).name);
   
   % replace the function line
   firstline   = fgetl(fid);
   secondline  = fgetl(fid);
   frewind(fid)
   wholefile   = fscanf(fid,'%c');     fclose(fid);
   
   if contains(firstline,'BFRA_')
      
      % remove BFRA_ from the first line
      newfirstline = strrep(firstline,'BFRA_','');
      
      % replace the first line in the whole file
      wholefile = strrep(wholefile,firstline,newfirstline);
   
   elseif contains(firstline,'bfra_')
      
      % remove bfra_ from the first line
      newfirstline = strrep(firstline,'bfra_','');
   
      % replace the first line in the whole file
      wholefile = strrep(wholefile,firstline,newfirstline);
   
   end
   
   
   % SECOND LINE
   if contains(secondline,'BFRA_')
      
      % remove BFRA_ from the second line
      newsecondline = strrep(secondline,'BFRA_','BFRA.');
      
      % replace the second line in the whole file
      wholefile = strrep(wholefile,secondline,newsecondline);
   
   elseif contains(secondline,'bfra_')
      
      % remove bfra_ from the second line
      newsecondline = strrep(secondline,'bfra_','');
   
      % replace the second line in the whole file
      wholefile = strrep(wholefile,secondline,newsecondline);
   
   end
   
   % REMAINING OCCURRENCES
   
   % replace other occurrences of BFRA_ and bfra_ with bfra.
   if contains(wholefile,'bfra_')
      
      wholefile = strrep(wholefile,'bfra_','bfra.');
      
   end
   
   % repeat for BFRA_
   if contains(wholefile,'BFRA_')
      
      wholefile = strrep(wholefile,'BFRA_','bfra.');

   end
   
   % rewrite the file
   fid = fopen(fname, 'wt');
   fprintf(fid,'%c',wholefile); fclose(fid);
   
end