function [Q,dQdt,t,hFig] = bfra_Qnonlin(a,b,Q0,t,varargin)
%BFRA_NONLINQ plots the theoretical discharge predicted by a/b values

% the loop is ugly but it's the easiest way to allow any size a,b,Q0.
% if I wanted to restrict two of the three a,b,Q0 to be scalar and let
% a third be a vector, I could check that the vector valued quantity
% and t have the right orientation for matrix multiplication
    
    plotFig = false;
    hFig    = [];
    if nargin==5
        plotFig = varargin{1};
    end
    
% This lets a scalar t or a vector t to be passed in. In both cases t is
% time elapsed since t=0, so to recover Q0 and dqdt0 we set t(1) = 0
    if numel(t) ~= 1 && t(1) ~= 0 
        t   = [0;t(:)];
    end

    numA    = numel(a);
    numB    = numel(b);
    numQ    = numel(Q0);
    numT    = numel(t);
    
    Q       = nan(numA,numB,numQ,numT);
    dQdt    = nan(numA,numB,numQ,numT);
    
    f       = @(a,b,Q0,t) (Q0^(1-b)+a*(b-1).*t).^(1/(1-b));
    
    for n = 1:numA
        for m = 1:numB
            for p = 1:numQ
                
                qtmp            = f(a(n),b(m),Q0(p),t);
                Q(n,m,p,:)      = qtmp;
                dQdt(n,m,p,:)   = -a(n).*qtmp.^b(m);
                
            end
        end
    end
                
    Q       = squeeze(Q);
    dQdt    = squeeze(dQdt);
    
    % only plot the first one for now, if I am getting an ensemble of Q(t)
    % I can add functionality later to plot some number of them
    if plotFig
        
        % get the characterisitc timescale
        tc  = bfra_characteristicTime(a(1),b(1),Q0(1));
        
        % get formatted strings for the legend
        showAB  = false;
        Qtstr   = bfra_QtString(a,b,Q0,showAB);
        tcstr   = bfra_tcString(a,b,Q0,showAB);
        
        % make a figure
        tileFigure();
        
        plot(t,Q);
        xlabel('$t \quad [T]$'); 
        ylabel('$Q(t) \quad [L/T]$'); 
        legend(Qtstr)
        axis tight
        hFig1 = figformat;
        

        nexttile
        plot(t./tc,Q./Q0); % hold on; plot(t./tc,Q./Q0); 
        xlabel('$t/t_c \quad [-]$'); ylabel('$Q/Q_0 \quad [-]$'); 
        legend(tcstr)
        
        axis tight
        ylim([0 1])
        
        hFig2 = figformat;
        
        % fix the axes if they got misaligned
        hFig1.backgroundAxis.Position = hFig1.mainAxis.Position;
        hFig2.backgroundAxis.Position = hFig2.mainAxis.Position;
        
                
    end
   
    

end

