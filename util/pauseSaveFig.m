function pauseSaveFig(savekey,filename,obj,varargin)
%PAUSESAVEFIG pause to save a figure using a defined keyboard key 'savekey' and
%filename
% 
% pauseSaveFig(savekey,filename) pauses and waits for savekey to save the
% current figure using filename
% 
% pauseSaveFig(savekey,filename,hobj) pauses and waits for savekey to save the
% figure designated by hobj using filename
% 
% pauseSaveFig(__,'Resolution',res) passes Resolution parameter to
% exportgraphics
% 
% pauseSaveFig(__,'pausetosave',true/false) turns on/off the pause behavior. If
% true, program execution is paused until savekey is pressed. If false, figures
% are saved without pausing.
% 
% See also:

%-------------------------------------------------------------------------------
p                 = inputParser;
p.FunctionName    = mfilename;
p.CaseSensitive   = true;

addRequired(   p,'savekey',               @(x)ischar(x)     );
addRequired(   p,'filename',              @(x)ischar(x)     );
addOptional(   p,'obj',             gcf,  @(x)isgraphics(x) );
addParameter(  p,'Resolution',      300,  @(x)isnumeric(x)  );
addParameter(  p,'pausetosave',     true, @(x)islogical(x)  );
addParameter(  p,'pauselogical',    true, @(x)ischar(x)     );

% NOTE: pauselogical not implemented but the idea is to have a logical condition
% that determines whether to pause or not like if(counter<maxiter); pause;

parse(p,savekey,filename,obj,varargin{:});

filename    = p.Results.filename;
savekey     = p.Results.savekey;
obj         = p.Results.obj;
figres      = p.Results.Resolution;
pausetosave = p.Results.pausetosave;
   
%-------------------------------------------------------------------------------
   
% convert the provided keys to ascii numbers
savekey = double(savekey);

if pausetosave == true

   msg = ['press ' savekey ' to save the figure, p to pause, '];
   msg = [msg 'or any other key to continue without saving'];

   disp(msg);

   ch = getkey();

   if ch==savekey
      exportgraphics(obj,filename,'Resolution',figres);
      disp('figure saved, press any key to continue');
      commandwindow
      pause; 
   elseif ch==112
      commandwindow
      pause;
   else
      commandwindow
   end
   
else 
   exportgraphics(gcf,fname,'Resolution',300);
   commandwindow
end
