function varargout = macfig(varargin)

   p               = inputParser;
   p.FunctionName  = 'macfig';
   p.CaseSensitive = true;
   p.KeepUnmatched = true;
  
   addParameter(p,'monitor','mac',@(x)ischar(x));
   addParameter(p,'size','full',@(x)ischar(x));
   
   parse(p,varargin{:}); 
   monitor  = p.Results.monitor;
   size     = p.Results.size;
   varargs  = unmatched2varargin(p.Unmatched);
   
    % 'mac' and 'full' are identical - they fill the screen
    % 'half', 'large', and 'horizontal' fill the top half
    % 'vertical' fills the half vertically
    % 'quarter' and 'medium' are identical, they fill a quarter horizontally
    % 'small' fills 1/16

   pos = get(0, 'MonitorPositions'); 
   switch monitor
      case 'mac'
         f = makeMacFigure(pos,size,varargs);
      case 'main'
         f = makeMainFigure(pos,size,varargs);
      case 'external'
         f = makeExternalFigure(pos,size,varargs);
   end
   
   switch nargout
      case 1
         varargout{1} = f;
   end
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function f = makeMacFigure(pos,size,varargs)
   
   pos = pos(1,:);
   
   switch size
      case 'full'        
         figpos = [pos(1) pos(2) pos(3) pos(4)];
      case 'horizontal'
         figpos = [pos(1) pos(3)/2 pos(3) pos(4)/2];
      case 'vertical'
         figpos = [pos(1) pos(2) pos(3)/2 pos(4)];
      case 'large'
         figpos = [pos(3)/4 pos(4)/4 pos(3)/1.75 pos(4)/1.25];
      case 'medium'
         figpos = [pos(3)/4 pos(4)/4 512   384]; % default fig size
%          figpos = [pos(3)/4 pos(4)/4 pos(3)/2.5 pos(4)/2];
      case 'small'
         figpos = [pos(3)/4 pos(4)/4 pos(3)/3 pos(4)/2.5];
      otherwise
         figpos = [pos(1) pos(2) pos(3) pos(4)];
   end
   
   f  = figure('Position',figpos,varargs{:});
end

function f = makeMainFigure(pos,size,varargs)
   
   pos = pos(3,:);
   
   switch size
      
      case 'full'
         figpos   = [1290,107,1152,624];
         
      otherwise
         pos      = pos(3,:);
         figpos   = [pos(1) pos(2) pos(3) pos(4)];
   end
   
   f  = figure('Position',figpos,varargs{:});
   
end

function f = makeExternalFigure(pos,size,varargs)
   
   pos = pos(2,:);
   
   switch size
      case 'full'        
         figpos = [pos(1) pos(2) pos(3) pos(4)];
      case 'horizontal'
         figpos = [pos(1) pos(3)/2 pos(3) pos(4)/2];
      case 'vertical'
         figpos = [pos(1) pos(2) pos(3)/2 pos(4)];
      case 'large'
         figpos = [pos(3)/4 pos(4)/4 pos(3)/1.75 pos(4)/1.25];
      case {'quarter','medium'}
         figpos = [pos(3)/4 pos(4)/4 pos(3)/2 pos(4)/2];
      case 'small'
         figpos = [pos(3)/4 pos(4)/4 pos(3)/3 pos(4)/2.5];
      otherwise
         figpos = [pos(1) pos(2) pos(3) pos(4)];
   end
   
   f  = figure('Position',figpos,varargs{:});
end
   
%    
% function f = legacyFigure(nargin,argsin)
%    
%     validOptions = {'main','mac','full','half','large','horizontal',    ...
%                     'vertical','medium','quarter','small','mainfull'};
%     if nargin>0
%         
%         if any(contains(validOptions,argsin{1}))
%             
%             monitor = varargin{1}; varargin=varargin(2:end);
%     
%             if strcmp(monitor,'mainfull')
%                 pos = pos(3,:);
%                 f = figure('Position', [pos(1) pos(2) pos(3) pos(4)],varargin{:}); 
%             elseif strcmp(monitor,'main')
%                 f = figure('Position',[1290,107,1152,624],varargin{:});
%             elseif contains(monitor,{'mac','full'})
%                 f = figure('Position',[0 1 1152 624],varargin{:});
%             elseif contains(monitor,{'half','large','horizontal'})
%                 f = figure('Position',[5 500 1152 624/2],varargin{:});
%             elseif contains(monitor,{'vertical'})
%                 f = figure('Position',[5 500 1152/2 624],varargin{:});
%             elseif contains(monitor,{'quarter','medium'})
%                 f = figure('Position',[5 500 1152/2 624/2],varargin{:});
%             elseif strcmp(monitor,'small')
%                 f = figure('Position',[5 500 1152/3 624/2],varargin{:});
%             else
%                 f = figure('Position',[0 1 1152 624],varargin{:});
%             end
%         else
%         
%         
%         f = figure('Position',[0 1 1152 624],varargin{:});
%             
%         end
%         
%     else
%         f = figure('Position',[0 1 1152 624]);
%         return;
%     end
%     
%     
% end
% 
