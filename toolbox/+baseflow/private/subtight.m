function h=subtight(m,n,p,varargin)
   %SUBTIGHT Create tight subplot.
   %  
   %  h = subtight(m,n,p,gap,marg_h,marg_w,varargin)
   %
   % Functional purpose: A wrapper function for Matlab function subplot. Adds
   % the ability to define the gap between
   % neighbouring subplots. Unfotrtunately Matlab subplot function lacks this
   % functionality, and the gap between
   % subplots can reach 40% of figure area, which is pretty lavish.
   %
   % Input arguments (defaults exist):
   %   gap- two elements vector [vertical,horizontal] defining the gap
   %            between neighbouring axes. Default value
   %            is 0.01. Note this vale will cause titles legends and labels
   %            to collide with the subplots, while presenting
   %            relatively large axis.
   %   marg_h  margins in height in normalized units (0...1)
   %            or [lower uppper] for different lower and upper margins
   %   marg_w  margins in width in normalized units (0...1)
   %            or [left right] for different left and right margins
   %
   % Output arguments: same as subplot- none, or axes handle according to
   % function call. 
   %
   % Issues & Comments: Note that if additional elements are used in order to
   % be passed to subplot, gap parameter must
   %       be defined. For default gap value use empty element- [].
   %
   % Usage example: h=subtightplot((2,3,1:2,[0.5,0.2])

   % parse inputs
   [m, n, p, gap, marw, marh] = parseinputs(m, n, p, mfilename, varargin{:});

   % below follows original subtightplot
   gap_vert   = gap(1);
   gap_horz   = gap(2);
   marg_lower = marh(1);
   marg_upper = marh(2);
   marg_left  = marw(1);
   marg_right = marw(2);

   %note n and m are switched as Matlab indexing is column-wise, while subplot
   %indexing is row-wise :(
   [subplot_col,subplot_row]=ind2sub([n,m],p);

   % note subplot suppors vector p inputs- so a merged subplot of higher
   %dimentions will be created
   % number of column elements in merged subplot
   subplot_cols=1+max(subplot_col)-min(subplot_col);
   % number of row elements in merged subplot
   subplot_rows=1+max(subplot_row)-min(subplot_row);

   % single subplot dimensions:
   %height=(1-(m+1)*gap_vert)/m;
   %axh = (1-sum(marg_h)-(Nh-1)*gap(1))/Nh;
   height=(1-(marg_lower+marg_upper)-(m-1)*gap_vert)/m;
   %width =(1-(n+1)*gap_horz)/n;
   %axw = (1-sum(marg_w)-(Nw-1)*gap(2))/Nw;
   width =(1-(marg_left+marg_right)-(n-1)*gap_horz)/n;

   % merged subplot dimensions:
   merged_height=subplot_rows*( height+gap_vert )- gap_vert;
   merged_width= subplot_cols*( width +gap_horz )- gap_horz;

   % merged subplot position:
   merged_bottom=(m-max(subplot_row))*(height+gap_vert) +marg_lower;
   merged_left=(min(subplot_col)-1)*(width+gap_horz) +marg_left;
   pos_vec=[merged_left merged_bottom merged_width merged_height];

   % h_subplot=subplot(m,n,p,varargin{:},'Position',pos_vec);
   % Above line doesn't work as subplot tends to ignore 'position' when same mnp
   % is utilized 
   % h=subplot('Position',pos_vec,varargin{:}); mgc removed varargin until
   % unmatched is dealt with
   h=subplot('Position',pos_vec);

   if (nargout < 1),  clear h;  end
end

%% input parser
function [m, n, p, gap, marw, marh] = parseinputs(m, n, p, funcname, varargin);

   classes = {'numeric','char','string'};
   atts = {'nonempty'};
   valg = @(x)validateattributes(x,classes,atts,'subtight','gap');
   valw = @(x)validateattributes(x,classes,atts,'subtight','marw');
   valh = @(x)validateattributes(x,classes,atts,'subtight','marh');
   parser = inputParser;
   parser.FunctionName = funcname;
   parser.addRequired('m',@(x)isnumeric(x));
   parser.addRequired('n',@(x)isnumeric(x));
   parser.addRequired('p',@(x)isnumeric(x));
   parser.addParameter('gap',[0.06 0.06],valg);
   parser.addParameter('marw',[0.06 0.06],valw);
   parser.addParameter('marh',[0.06 0.06],valh);
   parser.addParameter('style','userdef',@(x)ischarlike(x));
   parser.addParameter('gapstyle','userdef',@(x)ischarlike(x));
   parser.addParameter('wstyle','userdef',@(x)ischarlike(x));
   parser.addParameter('hstyle','userdef',@(x)ischarlike(x));

   parser.parse(m,n,p,varargin{:});
   m = parser.Results.m;
   n = parser.Results.n;
   p = parser.Results.p;
   gap = parser.Results.gap;
   marw = parser.Results.marw;
   marh = parser.Results.marh;
   style = parser.Results.style;
   gapstyle = parser.Results.gapstyle;
   wstyle = parser.Results.wstyle;
   hstyle = parser.Results.hstyle;

   [gap, marw, marh] = parsemargins(gap, marw, marh, style, gapstyle, wstyle, hstyle);

   % % not inplemented:
   % % put unmatched stuff into a dummy varargin to pass to subplot
   % unmatched = parser.Unmatched;
end

%% parse margins
function [gap,marw,marh] = parsemargins(gap,marw,marh,sty,gapsty,wsty,hsty)

   if isscalar(gap),    gap(2)   =  gap;  end
   if isscalar(marh),   marh(2)  =  marh; end
   if isscalar(marw),   marw(2)  =  marw; end

   tightmarg   = [0.04 0.04];
   fittedmarg  = [0.08 0.08];
   loosemarg   = [0.12 0.12];

   switch sty
      case 'tight'
         gap   = tightmarg;
         marw  = tightmarg;
         marh  = tightmarg;
      case 'fitted'
         gap   = fittedmarg;
         marw  = fittedmarg;
         marh  = fittedmarg;
      case 'loose'
         gap   = loosemarg;
         marw  = loosemarg;
         marh  = loosemarg;
      otherwise
         % case 'userdef'
   end

   switch gapsty
      case 'tight'
         gap   = tightmarg;
      case 'fitted'
         gap   = fittedmarg;
      case 'loose'
         gap   = loosemarg;
   end

   switch hsty
      case 'tight'
         marh  = tightmarg;
      case 'fitted'
         marh  = fittedmarg;
      case 'loose'
         marh  = loosemarg;
   end

   switch wsty
      case 'tight'
         marw  = tightmarg;
      case 'fitted'
         marw  = fittedmarg;
      case 'loose'
         marw  = loosemarg;
   end
end
