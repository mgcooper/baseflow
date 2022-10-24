
% need a script that demonstrates the different ways to use pointcloud

% this is the og method, it will move the bhat line down

% define the ref points as the median (or mean) for late time, and 95th
% percentile for early time
refpts = [quantile(-dqdt(itau),0.5) quantile(-dqdt,0.95)];

% plot the point cloud with early-time b=3, late-time b=1, and best-fit. the
% refpoints define the y-value in the point cloud that the early- and late-time
% lines are forced to pass through.
h = bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,'reflines',...
      {'early','late','bestfit'},'reflabels',true, ...
      'refpoints',refpts,'addlegend',true);
         
% the traditional 'storage coefficient' is the inverse of the intercept:
1/h.ab.late(1)
         
% replace blate=1 with blate = bhat, where bhat is the pareto fit exponent
h        =  bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
            'reflines',{'early','late','bestfit'},'reflabels',true, ...
            'refpoints',refpts,'addlegend',true);

% the storage coefficient can no longer be intrpreted as the inverse of the
% intercept. instead it is tau = tau0*(2-b)/(3-2*b)
1/h.ab.late(1)

% change the late-time refpoint so the blate=1 line moves down
refpts   =  [quantile(-dqdt(itau),0.3) quantile(-dqdt,0.95)];
ybar     =  quantile(-dqdt(itau),0.3); % quantile(-dqdt(itau),0.5);
xbar     =  median(q(itau),'omitnan'); % quantile(q(itau),0.5);
ahat     =  ybar/xbar^bhat;



scatter(xbar,ybar,60,'k','filled','s');


refpts   =  [quantile(-dqdt(itau),0.3) quantile(-dqdt,0.95)];

h        =  bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,    ...
            'reflines',{'early','late','userfit'},'reflabels',true, ...
            'refpoints',refpts,'userab',[ahat bhat],'addlegend',true);
            h.legend.AutoUpdate = 'off';
            scatter(xbar,ybar,60,'k','filled','s');
            
            
            
            
% this shows how the bestfit line does not pass through xbar/ybar unless they
% are the mean, and even then, it won't exactly pass through b/c nonlinear
% least squares is used. if linear least squares is used it should pass through
xbar     =  mean(q(itau),'omitnan'); % quantile(q(itau),0.5);
ybar     =  mean(-dqdt(itau),'omitnan'); % quantile(-dqdt(itau),0.5);
ahat     =  ybar/xbar^bhat;
refpts   =  [ybar quantile(-dqdt,0.95)];


h        =  bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
         'reflines',{'early','late','bestfit'},'reflabels',true, ...
         'refpoints',refpts,'addlegend',true);
         scatter(xbar,ybar,60,'k','filled','s');
         
         
         
         
         
         
         
         
% % % % % % % % % % % % % 
% % these are probably redundant with above but these were in the
% bfra_kuparuk_ppt_test script before i moved the phi and ahat estiamtion to
% bfra_kuparuk_ppt_events (now bfra_kuparuk_ppt_test) and settled on the best
% way to plot the point cloud  by using the median of q(itau) and adjusting yrefpoint

   %---------------------------------
   %     plot the point cloud
   %---------------------------------
%    refpts   = [mean(-dqdt(itau),'omitnan') quantile(-dqdt,0.95)];
%    h        = bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
%                'reflines',{'early','late','bestfit'},'reflabels',true, ...
%                'refpoints',refpts,'addlegend',true);
%    ahat     = h.ab.late(1);
   
   ybar     = median(-dqdt(itau),'omitnan'); % quantile(-dqdt(itau),0.5);
   xbar     = median(q(itau),'omitnan'); % quantile(q(itau),0.5);
   ahat     = ybar/xbar^bhat;
   
   h        = bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,    ...
               'reflines',{'early','late','userfit'},'reflabels',true, ...
               'userab',[ahat bhat],'addlegend',true);
            
%    % to mimic the way Brutsaert does it, set bhat = 1, then keep xbar fixed at
%    % mean(q(itau)) or median(q(itau)) and tune ybar by adjusting the quantile
%    % to a number less than 0.5 until about 5% of the values are below the line.
%    % This is equivalent to finding the line that, for a given mean (or median)
%    % flow, fits the smallest ~5% values of dq/dt across the range of q:
%    xbar     = quantile(q(itau),0.5); mean(q(itau),'omitnan'); 
%    ybar     = quantile(-dqdt(itau),0.5);
%    ahat     = ybar/xbar^1; 1/ahat
%    h        = bfra_pointcloud(q,dqdt,'blate',1,'mask',itau,    ...
%                'reflines',{'early','late','userfit'},'reflabels',true, ...
%                'userab',[ahat 1],'addlegend',true);

% % prob redundant w/above but coped here again bfore deleting bfra_kuparuk_ppt
% which was the ppt_test script before I put it all in a loop to do all three
% datasets at onece
%    refpts   = [mean(-dqdt(itau),'omitnan') quantile(-dqdt,0.95)];
%    h        = bfra_pointcloud(q,dqdt,'blate',bhat,'mask',itau,    ...
%                'reflines',{'early','late','bestfit'},'reflabels',true, ...
%                'refpoints',refpts,'addlegend',true);
%    ahat     = h.ab.late(1);
%    Q0hat    = (ahat*tau0)^(1/(1-bhat));   % m3/d
%    Qhat     = Q0hat*(bhat-2)/(bhat-3);
%    fdc      = fdcurve(Q(Q>0),'refpoints',[Q0hat Qhat],'units',utext);
%    pQexp    = fdc.fref;