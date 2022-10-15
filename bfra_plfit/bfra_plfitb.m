function [b,xmin,alpha,k] = bfra_fittau(x,varargin)
%BFRA_FITTAU returns [b,alpha,k]=bfra_fittau(x,varargin) where x is
%continuous data believed to follow an untruncated Pareto distribution with 
%some unknown xmin such that xhat=x-xmin. Any inputs to plfit can be passed
%in as varargin, where plfit is Aaron Clauset's function.

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p = MipInputParser;
p.FunctionName = 'bfra_plfitb';
p.addRequired('x',@(x)isnumeric(x));
p.addParameter('xmin',nan,@(x)isnumeric(x));
p.addParameter('range',1.01:0.01:25.01,@(x)isnumeric(x));
p.addParameter('limit',[],@(x)isnumeric(x));
p.addParameter('method','clauset',@(x)ischar(x));
p.addParameter('bootstrap',false,@(x)islogical(x));
p.addParameter('plotfit',false,@(x)islogical(x));
p.parseMagically('caller');

plotfit  = p.Results.plotfit;
range    = p.Results.range;
limit    = p.Results.limit;
xmin     = p.Results.xmin;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

   [x,~] = prepareCurveData(x,x);
   x     = x(x>0);
   if isnan(xmin)
      switch method
         case 'clauset'
            if bootstrap == true
               [alpha,xmin,sig,reps] = bootstrap_alpha(x,range,limit);
            else
               [alpha,xmin,L,D] = plfit(x,'range',range,'limit',limit);
            end
         case 'hanel'
            [~,xmin]          = plfit(x,'range',range,'limit',limit);
            [alpha,xmin,L,D]  = r_plfit(x,'rangemin',xmin,'alpha_min',  ...
                                 range(1),'alpha_max',range(end));
            % if I had some max value to consider, I could pass 'rangemax'
      end
   else
      alpha = plfit(x,'xmin',xmin,'range',range,'limit',limit);
   end
   k     = 1/(alpha-1);
   b     = 1+1/alpha;
   
   % also: b = (2*k+1)/(k+1)
   % and:  alpha = 1 + 1/k
   
   if plotfit == true
      aci = [alpha+2*sig alpha-2*sig];
%       aci = [3.5562 2.7685];
      figure; bfra_plplot(x,xmin,alpha,'trimline',true,'alphaci',aci,'labelplot',true);
   end
      
end

function [alpha,xmin,sig,reps] = bootstrap_alpha(x,range,limit)
   
   % first get xmin, bootstrap won't change this
   [~,xmin] = plfit(x,'range',range,'limit',limit);
   
   % now bootstrap alpha
   reps  = bootstrp(1000,@(x,xmin)plfit(x,'xmin',xmin),x,xmin);
   alpha = mean(reps);
   sig   = std(reps);

end

