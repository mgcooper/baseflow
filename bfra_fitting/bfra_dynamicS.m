function [Smin,Smax,dS] = bfra_dynamicS(a,b,qmin,qmax,varargin)

% input checks    
    b    = round(b,2);
    a    = a(:);
    b    = b(:);
    qmin = qmin(:);
    qmax = qmax(:);
    
% make a and b the same size
if numel(a)~=numel(b) && numel(a)==1
    a=a.*ones(size(b));
elseif numel(a)~=numel(b) && numel(b)==1
    b=b.*ones(size(a));
end

% make qmin/qmax the same size as a/b
if numel(qmin)~=numel(qmax)
    error('qmin and qmax must be the same size');
elseif numel(qmin)==numel(qmax) && numel(qmin)==1
    qmin=qmin.*ones(size(a));
    qmax=qmax.*ones(size(a));
elseif numel(qmin)==numel(qmax) && numel(a)==1
    a=a.*ones(size(qmin));
    b=b.*ones(size(qmin));
elseif numel(qmin)==numel(qmax) && numel(qmin)~=numel(a)
    error('qmin and qmax are not the same size as a and b');
end

% v3 merges KtimeS
    kflag = false;
    Ktime = nan(size(b));
    if nargin > 4
        kflag   = true;
        Ktime   = varargin{1};
    end
    if numel(Ktime)==1 && numel(Ktime)~=numel(b)
        Ktime = Ktime.*ones(size(b));
    end

if numel(a)==numel(b) && numel(a)==1
    
    if b>=0.95 && b<=1.05           % linear reservoir
        
        if kflag == true
            Smin    = Ktime*qmin;
            Smax    = Ktime*qmax;
        else
            Smin    = 1/a.*qmin;
            Smax    = 1/a.*qmax;
        end
        
    elseif b>=1.95 && b<=2.05       % exponential
        
        if kflag == true
            Smin    = 1/a.*log(a.*Ktime.*qmin.^2);
            Smax    = 1/a.*log(a.*Ktime.*qmax.^2);
        else
            Smin    = 1/a.*log(qmin);
            Smax    = 1/a.*log(qmax);
        end
        
    elseif b>2.05                   % super exponential
        if kflag == true
            Smin    = -Ktime/(2-b).*qmin;
            Smax    = -Ktime/(2-b).*qmax;
        else
            Smin    = -1/a/(2-b).*(qmax.^(2-b));
            Smax    = -1/a/(2-b).*(qmin.^(2-b));
           %dS      = -1/a/(2-b).*(qmax.^(2-b)-qmin.^(2-b));
        end
    else                            % sub exponential
        if kflag == true
            Smin    = -Ktime/(2-b).*qmin;
            Smax    = -Ktime/(2-b).*qmax;
        else
            Smin    = 1/a/(2-b).*(qmin.^(2-b));
            Smax    = 1/a/(2-b).*(qmax.^(2-b));
           %dS      = 1/a/(2-b).*(qmin.^(2-b)-qmax.^(2-b));
        end
    end
    
    dS      = Smax-Smin;
    
elseif numel(a)==numel(b) && (numel(a)==numel(qmin) || numel(qmin)==1)
    
    % first determine b=1, b=2, and otherwise
    Smin    = nan(size(a));
    Smax    = nan(size(a));
        
    % find indices where b=1, b=2, and b!=2
    ib1     = b>=0.95 & b<=1.05;
    ib2     = b>=1.95 & b<=2.05;
    ib2p    = b>2.05;
    ib2m    = true(size(b)); ib2m(ib1|ib2|ib2p) = false;
    b(ib1)  = 1.0;
    b(ib2)  = 2.0;
    
    % for reference: sum([ib1,ib2,ib2p,ib2m])
    % now b is ready to be used in each expression
    
    % dynamic a/b, mean qmin/qmax
    if numel(qmin)==1
        qmin_b1     = qmin;
        qmin_b2     = qmin;
        qmin_b2p    = qmin;
        qmin_b2m    = qmin;
        
        qmax_b1     = qmax;
        qmax_b2     = qmax;
        qmax_b2p    = qmax;
        qmax_b2m    = qmax;
        
    % dynamic a/b and dynamic qmin/qmax
    elseif numel(a)==numel(qmin)
        qmin_b1     = qmin(ib1);
        qmin_b2     = qmin(ib2);
        qmin_b2p    = qmin(ib2p);
        qmin_b2m    = qmin(ib2m);
        
        qmax_b1     = qmax(ib1);
        qmax_b2     = qmax(ib2);
        qmax_b2p    = qmax(ib2p);
        qmax_b2m    = qmax(ib2m);
    end

    % linear reservoir
    [S1,S2]     = dynamicS_b1(a(ib1),b(ib1),qmin_b1,qmax_b1,Ktime(ib1));
    Smin(ib1)   = S1;
    Smax(ib1)   = S2;

    % exponential reservoir
    [S1,S2]     = dynamicS_b2(a(ib2),qmin_b2,qmax_b2,Ktime(ib2));
    Smin(ib2)   = S1;
    Smax(ib2)   = S2;

    % power law reservoir with infinite storage (S2 is the upper limit)
    [S1,S2]     = dynamicS_b2p(a(ib2p),b(ib2p),qmin_b2p,qmax_b2p,Ktime(ib2p));
    Smin(ib2p)  = S1;
    Smax(ib2p)  = S2;

    % power law reservoir with finite drainage
    [S1,S2]     = dynamicS_b2m(a(ib2m),b(ib2m),qmin_b2m,qmax_b2m,Ktime(ib2m));
    Smin(ib2m)  = S1;
    Smax(ib2m)  = S2;

    dS          = Smax-Smin;
   
end

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% subfunctions
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    function [Smin,Smax] = dynamicS_b1(a,b,qmin,qmax,ktime)
        
        if all(~isnan(ktime))
            Smin    = ktime.*qmin;
            Smax    = ktime.*qmax;
        else
            Smin    = 1./a.*qmin.^b;
            Smax    = 1./a.*qmax.^b;
        end
    end
    
    function [Smin,Smax] = dynamicS_b2(a,qmin,qmax,ktime)
        
        if all(~isnan(ktime))
            Smin    = 1./a.*log(a.*ktime.*qmin.^2);
            Smax    = 1./a.*log(a.*ktime.*qmax.^2);
        else
            Smin    = 1./a.*log(qmin);
            Smax    = 1./a.*log(qmax); 
        end
    end
    
    function [Smin,Smax] = dynamicS_b2m(a,b,qmin,qmax,ktime)
        if all(~isnan(ktime))
            Smin    = ktime./(2-b).*qmin;
            Smax    = ktime./(2-b).*qmax;
        else
            Smin    = 1./a./(2-b).*(qmin.^(2-b));
            Smax    = 1./a./(2-b).*(qmax.^(2-b));
        end
    end

    function [Smin,Smax] = dynamicS_b2p(a,b,qmin,qmax,ktime)
        if all(~isnan(ktime))
            Smin    = -ktime./(2-b).*qmin;
            Smax    = -ktime./(2-b).*qmax;
        else
            
           %ktime   = -1./a./(2-b).*qmax;
            
            Smin    = -1./a./(2-b).*(qmax.^(2-b));
            Smax    = -1./a./(2-b).*(qmin.^(2-b));
        end
    end

end
