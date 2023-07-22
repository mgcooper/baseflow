function debugplot_nlinfit(X,y,yfit)

pos = get(0,'defaultfigureposition');
figure('Position',[pos(1) pos(2) 2*pos(3) pos(4)]); 
subplot(1,2,1);
loglog(X,y,'-o'); hold on; plot(X,yfit,':');
xlabel('log Q'); ylabel('log -dQ/dt');
legend('data','fit');

subplot(1,2,2);
plot(X,y,'-o'); hold on; plot(X,yfit,':');
xlabel('Q'); ylabel('-dQ/dt');
legend('data','fit');
