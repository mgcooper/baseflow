function [phi,a] = bfra_eventphi(K,Fits,A,D,L,varargin)

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
p = MipInputParser;
p.StructExpand = false;
p.FunctionName = 'bfra_eventphi';
p.addRequired('K',@(x)istable(x));
p.addRequired('Fits',@(x)isstruct(x));
p.addRequired('A',@(x)isnumeric(x));
p.addRequired('D',@(x)isnumeric(x));
p.addRequired('L',@(x)isnumeric(x));
p.addParameter('blate',1,@(x)isnumeric(x));
p.addParameter('soln1','',@(x)ischar(x));
p.addParameter('soln2','',@(x)ischar(x));
p.addParameter('usefits',false,@(x)islogical(x));
p.addParameter('theta',0,@(x)isnumeric(x));
p.addParameter('isflat',true,@(x)islogical(x));
p.parseMagically('caller');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

warning off

% take out the data and init the output
q           = Fits.q;
dqdt        = Fits.dqdt;
tags        = Fits.eventTag;
eventlist   = rmnan(unique(tags));
numevents   = numel(eventlist);
phi         = nan(numevents,1);
a           = nan(numevents,1);

for n = 1:numevents
   
   event    = K.eventTag(n);
   ifit     = Fits.eventTag == event;
   thisq    = q(ifit);
   thisdqdt = dqdt(ifit);

   if isempty(thisq) || isempty(thisdqdt)
      continue;
   else
      
      % put a line of slope 3 and 1/1.5 through the point cloud. note that
      % a in ab is returned as the transformed value i.e. exp(intercept)
      [~,ab1]  = bfra_refline(thisq,-thisdqdt,'refslope',3,'plot',false);
      [~,ab2]  = bfra_refline(thisq,-thisdqdt,'refslope',blate,'plot',false);

      a1 = ab1(1); a2 = ab2(1); b2 = ab2(2);
      
      % choose appropriate solutions
      if isempty(soln1) && isempty(soln2)
   
         if blate==1
            phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                          'soln1','PK62','soln2','BS03');
         elseif blate==3/2
            phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                          'soln1','PK62','soln2','BS04');
         elseif blate>1 && blate<2
            phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,          ...
                                          'soln1','RS05','soln2','RS05');
         else
            % phi remains nan
         end
         
      % user-specified solutions
      else
         phi(n) = bfra_fitphi(a1,a2,b2,A,D,L,'isflat',true,             ...
                                          'soln1',soln1,'soln2',soln2);
      end
      
      a(n)     = a2;
   end
end

warning on
