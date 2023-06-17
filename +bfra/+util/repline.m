function repline(filename,str_find,str_repl,varargin)

opts = bfra.util.optionParser('appendblanks',varargin(:));

fid = fopen(filename,'r');        % Open File to read
n = 1;
newlines = {[]};
while true
   thisline = fgetl(fid);
   if ~ischar(thisline); break; end  % end of file
   if ismember(thisline,str_find)
      
      newlines{n} = thisline;
      
      if opts.appendblanks == true
         n = n+1; 
         newlines{n} = ''; 
      end

      % this allows str_repl to be multiple lines but I didn't check for 
      if iscellstr(str_repl)
         for m = 1:numel(str_repl)
            n = n+1;
            newlines{n} = str_repl{m};
         end
      else
         n = n+1;
         newlines{n} = str_repl;
      end

      % if the next line is not blank, insert a blank line then the next line
      if opts.appendblanks == true

         checkline = fgetl(fid);

         % insert a blank no matter what
         n = n+1; 
         newlines{n} = '';

         % if the line wasn't blank, or was a tab, insert it after the blank
         if ~all(isempty(checkline)) && ~isequal(checkline,sprintf('\t')) && ...
               ~isequal(checkline,'   ')
            n = n+1;
            newlines{n} = checkline;
         end
      end
   else
      newlines{n}=thisline;
   end
   n = n+1;
end
fclose(fid);

fid = fopen(filename,'w');            % Open file to write
for n=1:length(newlines)
   fprintf(fid,'%s\n',newlines{n});
end
fclose(fid);


%% doesn't work, still over-writes the line
% fid = fopen(funcname,'r+');        % Open File to read
% newlines = {};
% while true
%    thisline = fgetl(fid);
%    if ~ischar(thisline); break; end  % end of file
%    if contains(thisline,str_find2)
%       newlines{1} = '';
%       newlines{2} = str_repl2;
%       newlines{3} = '';
%       % thisline = fgetl(fid);
%       % fid2=fopen('test.m','w');            % Open file to write
% 
%       % Call fseek between read and write operations
%       fseek(fid, 0, 'cof');
% 
%       fprintf(fid,['%s',char([13,10])],newlines{:});
%       break
%    end
% end
% fclose(fid);



%% this works to create an entirely new file

% fid = fopen(funcname,'r');        % Open File to read
% i = 1;
% A = {[]};
% while true
%    thisline = fgetl(fid);
%    if ~ischar(thisline); break; end  % end of file
%    if contains(thisline,str_find2)
%       A{i}=thisline;
%       A{i+1} = '';
%       A{i+2} = str_repl2;
%       A{i+3} = '';
%       thisline = fgetl(fid);
%       i = i+3;
%    else
%       A{i}=thisline;
%    end
%    i = i+1;
% end
% fclose(fid);
% 
% fid2=fopen('test.m','w');            % Open file to write
% for i=1:length(A)-1
%    fprintf(fid2,['%s',char([13,10])],A{i});
% end
% fclose(fid2);

