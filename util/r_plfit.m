function [alpha,xmin,L,D,out] = r_plfit(z,varargin)
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Author: R Hanel
% generation 1 :::::::::::::::::::::::::::::::::::::
% 1.1)  latest modification on 9.6.2016 
% 1.2)  latest modification on 16.6.2016 
%   REM: a bug in setting rangemax plus hist option was fixed
% 1.3)  latest modification on 11.07.2016
%   REM: a bug was fixed ... var name infofl had to be infoflg
% 1.4)  latest modification on 12.07.2016   
%       out.plfit.xyz -> out.fit.xyz
%       out.dom_max -> out.xmax
%       out.dom_min -> out.xmin
%       option + varname Nrep_implicit -> Nimplicit
%       option Nrep_tail -> Ntail
% 1.5)  latest modification on 04.08.2016   
%       alternative cdat2 option implemented ... but results are mediocre
% generation 2 :::::::::::::::::::::::::::::::::::::
% 2.1)  latest modification on 10.08.2016   
%       simplified code introducing helpfunction h_implicit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% arg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% z ... is the recorded data, 
%       by default we assume that the data are samples 
%       of strictly positive natural numbers and that 
%       the range of data runs between 
%       min(z), min(z)+1, ... ,max(z)+1, max(z)
%
%       If z contains different elements then use the argument 
%       'range' to set the elements of data you want to consider 
%       for the fit or 'urange' to use the uniqe data elements as range
%       or first make a histogram of your data and then use the 'hist'
%       option for inputing a histograms and 'range' for seting the
%       bin-centroids as range
%       
%       the data gets cleaned (Inf, NaN, negative data, 0 get removed)
%       the data also gets filtered using the range property 
%
%       REM: the remaining elements are stored in zz
%       the number of elements in zz is NN 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% varargins:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 'alpha_min' ... sets the minimal alpha for the search 
%       default: alpha_min=0 
% 'alpha_max', ... sets the maximal alpha for the search 
%       default: alpha_max=5 
% 'range' ... sets the considered sample space! 
%       for instance if the elements 
%       range=[0.5,1,3,5,6.5,7,16.5,17,21,50,51,52,110] 
%       form the considered sample space then use
%       r_plfit(data,'range',range) to set the range property
%       Also, the sample may contain elements that should be 
%       excluded from the fit, for instance if the powerlaw 
%       possesses a shoulder or an exponential cutoff;
%       the range property can be used to filter out such 
%       unwanted elements
%       default: range=min(z):max(z) 
% 'urange' ... the urange property can be set to handle data 
%       that is not necessarily integer but the range of the 
%       power law can be determined by range=unique(z)
% 'rangemin' ... rangemin sets the minimal range to max(min(range),rangemin)
% 'rangemax' ... rangemax sets the maximal range to min(Inf,rangemax)
% 'eps' ... the precission of the implicit algorithm
% 'hist' ... with the hist property one declares the data z to already 
%       be a histogram of the data
% 'nolf' ... (nolfcutoff) if set no low frequency cut-off gets determined
%       and fit data on full (filtered & cleaned) range x
%       default: compute low frequency cut-off with NN*p_i>=Nmin
% 'cdat' ... if the continous distribution flag is set the probabilities
%       are normalized as continous data (experimental)
% 'Nmin' ... sets the minimal number of elements per consdidered bin 
%       i.e. we want NN*p_i>Nmin and exclude all states i 
%       that are expected to appear less frequent 
%       default: Nmin=2;
% 'Ncut' ... specifies the number of values alpha in the search 
%       range of alpha that get evaluated each iteration so that 
%       after m iterations the precision of alpha becomes 
%       (alpha_max-alpha_min)/(Ncut/2)^m  
%       REM: the factor Ncut/2 comes from cutting a alpha range 
%       two times the previous alpha increment into Ncut pieces!
% 'Ntail' ... sets the maximal number of iterations used for 
%       determining the largest tail element that has sufficiently 
%       many samples  
% 'Nimplicit' ... maximal number of iterations used for finding the
%       implicit solution of the ml estimator 
% 'plot' ... if set r_plfit will plot its results
% 'fig' ... if set r_plfit will plot its results and explicitly open a
%       new figure
% 'info' ... if set r_plfit will output info (critical info is allways displayed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Not yet implemented
% 'autormin' ... tries to detect rangemin automatically (not yet implemented)
% 'autormax' ... tries to detect rangemax automatically (not yet implemented)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% call the help
if length(z)==length('help')
if strcmp(z,'help')==1
    msg='Using function out = r_plfit(data,varargin)\n';
    msg=[msg 'r_plfit can be used to fit the exponent out.exponent of power laws\n'];
    msg=[msg 'in three basic different modes\n'];
    msg=[msg '(1) out = r_plfit(x) with data being samples x=[x1,...,xN] from N experiments\n'];
    msg=[msg '\t in this mode out.exponent returns the estimated exponend lambda of \n'];
    msg=[msg '\t the distribution p(z_i|lambda) one has sampled from\n'];    
    msg=[msg '(2) out = r_plfit(k,''hist'') with data being histograms k=[x1,...,xW]\n'];
    msg=[msg '\t of W distinct events i=1...W with magnitudes z=[z1,...,zW]\n'];
    msg=[msg '\t here out.exponent also returns lambda\n'];
    msg=[msg '(3) out = r_plfit(k) with data being histograms k=[x1,...,xW]\n'];
    msg=[msg '\t works equivalent to (1) but with k as data one computes the\n'];
    msg=[msg '\t frequency distribution of x with exponent alpha~1+1/lambda\n'];
    msg=[msg '\n'];
    msg=[msg 'Fitting with data x:\n'];
    msg=[msg '\t By default r_plfit(x) assumes that x consists of natural numbers and\n'];
    msg=[msg '\t the sample space (magnitudes) z={i|min(x)<=i<=max(x)}\n']; 
    msg=[msg '\t if magnitudes z_i are not of this form one either uses\n']; 
    msg=[msg '\t if magnitudes z_i are not of this form one either uses:\n']; 
    msg=[msg '\t out = r_plfit(x,''urange'') ... which sets z=[z_1,...,z_W]=unique(x)\n'];
    msg=[msg '\t where W is then the number of unique values of data points in x\n'];
    msg=[msg '\t out = r_plfit(x,''urange'',''rangemin'',zmin,''rangemax'',zmax) can be used\n'];         
    msg=[msg '\t to specify a fit range zmax <= z_i <= zmin (default zmin=min(x), zmax=max(x))\n']; 
    msg=[msg '\t To control the data range individually use out = r_plfit(x,''range'',z)\n'];
    msg=[msg '\n'];
    msg=[msg 'Fitting with histograms k\n'];
    msg=[msg '\t Using k (mode 3) for fitting the frequenvcy distribution with exponent alpha\n'];
    msg=[msg '\t works in exactly the same way as the sample distribution estimating the\n'];
    msg=[msg '\t exponent lambda using x.\n']; 
    msg=[msg '\t out = r_plfit(k,''hist'') works similar however one should note that\n'];
    msg=[msg '\t in this mode r_plfit assumes by default that z=[1,2,...,W]\n']; 
    msg=[msg '\t The option ''urange'' has no effect in this mode and gets ignored if set\n']; 
    msg=[msg '\t Otherwise use out = r_plfit(k,''hist'',''range'',z) to set the event magnitudes z\n'];
    msg=[msg '\t ''rangemin'' and ''rangemax'' options work in exactly the same way as before\n'];
    msg=[msg '\n'];
    msg=[msg 'Automatic low frequency cutoff \n'];
    msg=[msg '\t By default r_plfit runs an iterative search for an optimal low frequency cutoff\n'];
    msg=[msg '\t lf cutoff is set at index i where |Nz_i^lambda/N-Nmin| is minimal where Nmin=1\n'];
    msg=[msg '\t by default and N the length of x=[x1,...,xN]; Nmin can be set using the\n'];
    msg=[msg '\t ''Nmin'' option. If maxrange is smaller than the predicted lf cutoff then the\n'];
    msg=[msg '\t cutoff has no effect. Note that in the out = r_plfit(k) mode the lf cutoff mechanism\n'];
    msg=[msg '\t effectively acts as ahigh frequency cutoff with respect to the data x\n'];    
    msg=[msg '\t the option ''nolf''  switches of the lf cutoff \n'];
    msg=[msg '\n'];
    msg=[msg 'out = r_plfit(data,...,''plot'') displays the fit over the data\n'];
    msg=[msg 'in double logarithmic coordinates (loglog plot)\n'];
    msg=[msg '''fig'' behaves like ''plot'' but explicitly opens a new figure\n']; 
    msg=[msg '''exp_min'' can be used to specify the minimal search value exp_min (default =0)\n']; 
    msg=[msg 'for out.exponent. Similarly r_plfit(data,...,''exp_max'',expmax) sets the minimal\n']; 
    msg=[msg ' search value (default =5) to expmax\n'];
    msg=[msg '''eps'' ... set absolute error eps (default eps=1e-10) for out.exponent \n'];
    msg=[msg '\n'];
    msg=[msg 'Other options to control the performance of the algorithm:\n'];
% 'cdat' ... if the continous distribution flag is set the probabilities
%       are normalized as continous data
    msg=[msg '''Ncut'' ... specifies the number of values alpha in the search range\n'];
    msg=[msg 'of out.exponent. After m iterations the precision of out.exponent becomes\n']; 
    msg=[msg '(expmax-expmin)/(Ncut/2)^m => m(eps)~2*(log(expmax-expmin)-log(eps))/Ncut\n'];  
    msg=[msg '''Nimplicit'' sets the maximal number of implicit iteration for finding \nthe exponent (default 80) of iterations\n'];
    msg=[msg 'searching implicitly for out.exponent. one should use Nimplicit>m(eps)\n']; 
    msg=[msg '''Ntail'' sets the maximal number of iterations for the lf cutoff\n'];
    msg=[msg '''info'' if set will output info over the run stored in out.info at runtime!\n']; 
    msg=[msg 'Bug reports to: rudolf.hanel@meduniwien.ac.at\n'];         
    fprintf(1,msg);
    out=msg;
    return;
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% number of data items
N=numel(z);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Default values
xflg=0;
cleanxflg=0;
histflg=0;
cdatflg=0;
rangemin=0;
rangemax=Inf;
Nrangeitems_max=1e6;

EPS=1e-10;
issmall=1e-50;

alpha_min=0;
alpha_max=5;

lfcutoff=1;
plotflg=0;
newfigflg=0;

testflg=1;

Nmin=1;
Ninc=50;
Ntail=80;
Nimplicit=80;
Nrep_cdat=80;

rep_min=3;
Amlthres=0.1;
infoflg=0;
runinfo='start ...\n';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% varargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
id=0;
while id<length(varargin)
  id=id+1;
  if ischar(varargin{id})
    switch varargin{id}
        case 'exp_min'
            alpha_min = varargin{id+1};
            id=id+1;
        case 'exp_max'
            alpha_max = varargin{id+1};
            id=id+1;
        case 'Ntail'
            Ntail = varargin{id+1};
            id=id+1;
        case 'Nimplicit'
            Nimplicit = varargin{id+1};
            id=id+1;
        case 'Nmin'
            Nmin = varargin{id+1};
            id=id+1;
        case 'Ncut'
            Ninc = varargin{id+1};
            id=id+1;
        case 'range'
            xrange = varargin{id+1};
            xflg=1;
            id=id+1;
        case 'rangemin'
            rangemin = varargin{id+1};
            id=id+1;
        case 'rangemax'
            rangemax = varargin{id+1};
            id=id+1;
        case 'urange'
            xflg=2;
        case 'cdat'
            cdatflg=1;
            lfcutoff=0;
            xflg=2; % for continous data we require the urange
        case 'cdat2'
            cdatflg=1;
            testflg=2;
            lfcutoff=0;
            xflg=2; % for continous data we require the urange
        case 'hist'
            histflg=1;
        case 'nolf'
            lfcutoff=0;
        case 'info'
            infoflg=1;
        case 'plot'
            plotflg=1;
        case 'fig'
            plotflg=1;
            newfigflg=1;
        case 'cleanrange'
            cleanxflg=1;
        case 'eps'
            EPS = varargin{id+1};
            id=id+1;
        otherwise
            msg=['no such argument [' varargin{id} '] ->skip ...\n'];
            runinfo=[runinfo msg];
            if infoflg==1, fprintf(1,msg); end
    end
  end
end

msg='handling arguments ...\n';
runinfo=[runinfo msg];
if infoflg==1, fprintf(1,msg); end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% handle hist property, data filtering etc ...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data=histogram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if histflg==1
    %data is histogram data
    msg=['handling histogram input case ' num2str(xflg), ' ...\n'];
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end
    k=z; zz=z;
    %... urange property is specified
    if xflg==2
        msg='r_plfit: urange property has no effect together with hist input -> set default range case 0 ...\n';
        runinfo=[runinfo msg];
        if infoflg==1, fprintf(1,msg); end
        xflg=0;
    end
    % if input is histogram set range to...
    switch xflg
    %... default range if range is not specified
        case 0
            x=1:length(k);
            rangemin=max(rangemin,1);
            rangemax=min(rangemax,length(k));
    %... range property is specified
        case 1
            if length(k)==length(xrange)
                x=xrange;
                rangemin=max(rangemin,min(x));
                rangemax=min(rangemax,max(x));
            else
                fprintf(1,runinfo); 
                error('r_plfit: range and histogram must have same length!!!');
            end
        otherwise
            fprintf(1,runinfo); 
            error('this should not happen 1 !!!');
    end
    xidv=find(x>=rangemin & x<=rangemax);
    W=length(x);
    N=sum(k);
    xx=x(xidv);
    kk=k(xidv);
    WW=length(xx);
    NN=sum(kk);
else
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data=samples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    msg='cleaning data input ... \n';
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end % mgc simplified these
    zz=z(z>0);
    zz=zz(abs(log(zz))<Inf);
    zz=zz(~isnan(zz));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    rangemin=max(rangemin,min(zz));
    rangemax=min(rangemax,max(zz));
    if rangemin>rangemax
        fprintf(1,runinfo); 
        error('r_plfit requires rangemin<rangemax!'); 
    end
    zz=zz(zz>=rangemin & zz<=rangemax);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if (((max(zz)-min(zz))>Nrangeitems_max) & (xflg==0))
        msg1=['Length of r_plfit default range rangemin:1:rangemax ' num2str((max(zz)-min(zz))) 'is too large!\n'];
        msg2=['Maximum allowed: ' num2str(Nrangeitems_max) '; => r_plfit tries the urange option!\n'];
        msg3='Otherwise, try again by setting the range property manually with options: range, maxrange, minrange!\n';
        runinfo=[runinfo msg1 msg2 msg3];
        if infoflg==1, fprintf(1,[msg1 msg2 msg3]); end
        xflg=2;
    end
    msg=['handling data input case ' num2str(xflg), ' ...\n'];
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end
    switch xflg
    %... default range if range is not specified
        case 0
            x=tocol(min(zz):max(zz));        % mgc tocol
            rangemin=max(rangemin,min(x));
            rangemax=min(rangemax,max(x));
    %... range property is specified
        case 1
            x=xrange;
            rangemin=max(rangemin,min(x));
            rangemax=min(rangemax,max(x));
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % filter
            uz=unique(zz);
            uzon=zeros(size(uz));
            for uid=1:length(uz)
             v=find(uz(uid)==x);
                if length(v)>0, uzon(uid)=1; end
            end
            uzoffidv=find(uzon==0);
            for uid=1:length(uzoffidv)
                v=find(uz(uzoffidv(uid))==zz);
                if length(v)>0, zz(v)=-1; end
            end
            zz=zz(zz>0);
    %... urange property is specified
        case 2
            x=unique(zz);
            rangemin=max(rangemin,min(x));
            rangemax=min(rangemax,max(x));
        otherwise
            fprintf(1,runinfo); 
            error('this should not happen 1 !!!');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sort data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    zz=sort(zz);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filter sample-space
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    if xflg==1 & cleanxflg==1,
    if cleanxflg==1
        msg='cleaning sample space ...\n';
        runinfo=[runinfo msg];
        if infoflg==1, fprintf(1,msg); end
        uz=unique(zz);
        xon=zeros(size(x));
        for xid=1:length(uz)
            v=find(uz==x(xid));
            if ~isempty(v), xon(xid)=1; end
        end
        x=x(find(xon==1));
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute histogram
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    msg='computing histogram ...\n';
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end
    x=sort(x);
    W=length(x);
    maxx=max(x);
    while 1
        xidv=find(x>=rangemin & x<=rangemax);
        if length(xidv)==0
            rangemin=max(rangemin-1,issmall); rangemax=min(rangemax+5,maxx); 
        else
            break;
        end
    end
%     k=zeros(size(x));
%     [k,xdummy]=hist(zz,x); % mgc commented out to use histogram instead

   % mgc start - i think in one case, edges needs semicolons, and the other not
    x             = x(:);     % this is what was needed to make it work
    d             = diff(x)/2;
    edges         = [x(1)-d(1); x(1:end-1)+d; x(end)+d(end)];
    edges(2:end)  = edges(2:end)+eps(edges(2:end));
    [k,~]         = histcounts(zz,edges); 
    % mgc end (comment this out and uncomment the hist call if broken)
    
    N=sum(k);    
    xx=x(xidv);
    kk=k(xidv);
    WW=length(xx);
    NN=sum(kk);
end
[a,b]=size(kk); if b==1, kk=kk'; end
[a,b]=size(xx); if b==1, xx=xx'; end
%figure; plot(k); pause;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Maximum likelihood estimate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% find ML optimal alpha
xrangemax=max(xx);
xrangemax2=xrangemax; 
idrmax=WW;
idrmax_1=0;
idrmax_2=0;
QQ=kk.*log(xx);
%csQ=cumsum(Q);

% xmin=min(xx);
% xmax=max(xx);
xmin=rangemin;
xmax=rangemax;
alphbest=0;

param.Nimplicit=Nimplicit;
param.Ninc=Ninc;
param.alpha_max=alpha_max;
param.alpha_min=alpha_min;
param.cdatflg=cdatflg;
param.testflg=testflg;
param.infoflg=infoflg;
param.issmall=issmall;
% param.xmin=rangemin;
% param.xmax=rangemax;

if lfcutoff==1
%%%%%%%%%%%%%%%%%%%%%%%%            
%% optimize low frequency cut-off for ML optimal alpha
    idrmax_1=WW;
    msg='find exponent (lf cut-off is on) ...\n';
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end
    for rep1=1:Ntail
        xridv=find(xx<=xrangemax2);
        idrmax_2=idrmax_1;
        idrmax_1=idrmax;
        idrmax=max(xridv);
%%%%%%%%%%%%%%%%%%%%%%%%        
        xxx=xx(xridv);
        kkk=kk(xridv);
        WWW=length(xridv);
        NNN=sum(kkk);
%        QQQ=sum(QQ(xridv));        
        QQQ=QQ(xridv);        
%%%%%%%%%%%%%%%%%%%%%%%%        
%%% optimize alpha for Ninc alpha values
        loopmsg=['lf-loop: ', num2str(rep1),' '];
        [alphbest,runinfo]=h_implicit(NNN,xxx,QQQ,runinfo,loopmsg,alphbest,param);
        Aml=alphbest;
        yml=xx.^(-Aml);
        yml=yml/sum(yml);
        gugu=abs(NN*yml-Nmin);
        v=find(gugu==min(gugu));
        if Aml>Amlthres, idrmax=max(v); else idrmax=WW; end
        if (idrmax==idrmax_1 || idrmax==idrmax_2) && rep1>=rep_min, break; end
        idrmax=max(idrmax,1);
        xrangemax2=xx(idrmax);
    end
else
    msg='find exponent (lf cut-off is off) ...\n'; 
    runinfo=[runinfo msg];
    if infoflg==1, fprintf(1,msg); end
    [alphbest,runinfo]=h_implicit(NN,xx,QQ,runinfo,'',alphbest,param);
    Aml=alphbest;
    idrmax=WW;
end
msg='preparing output ...\n'; 
runinfo=[runinfo msg];             
if infoflg==1, fprintf(1,msg); end

xlfcutoff=1:idrmax;

% Quality of fit;
xxx=xx(xlfcutoff);
plf=xxx.^(-Aml); %Aml,
plf=plf/sum(plf);
p=xx.^(-Aml); %Aml,
p=p/sum(p);

ylf=kk(xlfcutoff)/sum(kk(xlfcutoff));
y=kk/sum(kk);
if plotflg==1
    if newfigflg==1, out.f = figure; end
%    y=k/sum(k);
    out.ab = olsfit(log(xxx),log(plf)); % mgc
    out.h1 = loglog(xxx,ylf,'r'); hold on;
    %out.h1 = loglog(xxx,y,'r'); hold on;
    out.h2 = loglog(xxx,plf);
    out.h3 = loglog(xxx(idrmax),plf(idrmax),'go');
%    hold off; 
    pause(0.01);
end
% output
out.runinfo=runinfo;
out.N = NN; % data in range
out.K=kk;

out.fit.data=zz;
out.fit.Nsamples = N;
out.fit.range=xx;
out.fit.lf_cutoff_on=lfcutoff;
out.fit.Nmin = Nmin;
out.fit.alpha_min=alpha_min;
out.fit.alpha_max=alpha_max;
out.fit.Ntail=Ntail;
out.fit.Nimplicit=Nimplicit;
out.fit.Ninc=Ninc;

out.exponent = Aml;
out.KSall = max(abs(cumsum(y)-cumsum(p)));
out.KSrange = max(abs(cumsum(ylf)-cumsum(plf)));
out.xmax = max(xx);
out.xmin = min(xx);
out.rangemax = rangemax;
out.rangemin = rangemin;
out.lf_rangemax = max(xxx);
out.lf_cutoffid = idrmax;

% mgc:
out.b = 1+1/Aml;
alpha = Aml;
D     = out.KSrange;

return;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [alphbest,runinfo]=h_implicit(NN,xx,QQ,runinfo,loopmsg,alphbest,param)

Nimplicit=param.Nimplicit;
Ninc=param.Ninc;
alpha_max=param.alpha_max;
alpha_min=param.alpha_min;
cdatflg=param.cdatflg;
testflg=param.testflg;
infoflg=param.infoflg;
issmall=param.issmall;

xmin=min(xx);
xmax=max(xx);

dalph=(alpha_max-alpha_min)/Ninc;
alphav=alpha_min:dalph:alpha_max;
QQQ=sum(QQ);
for rep2=1:Nimplicit
    msg1=['implicit: ', num2str(rep2)]; 
    msg2=[' accuracy: ' ,num2str(log(dalph/eps)/log(10))];
    msg3=[' alpha: ', num2str(alphbest),' ...\n'];
    runinfo=[runinfo loopmsg msg1 msg2 msg3];
    if infoflg==1, fprintf(1,[loopmsg msg1 msg2 msg3]); end      
    d=zeros(size(alphav));
    count=0;
    logxx=log(xx);
    for alph=alphav
        count=count+1;
        px=xx.^(-alph);
        px=px/sum(px);
        if cdatflg==0
            FFF=NN*sum(px.*logxx);
        else
            if abs(alph-1)<issmall, if alph<1 alph=1-issmall; else alph=1+issmall; end; end;
            % BAUSTELLE
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            switch testflg
                case 1
                % PRIMITIVE ESTIMATOR FOR xmax and xmin ....
                    dhi=0; dlo=0;
                    xmax2=xmax+dhi;
                    xmin2=xmin-dlo;
                    hxmax=xmax2.^(1-alph);
                    hxmin=xmin2.^(1-alph);
                    if hxmax>hxmin, h1=max(hxmax-hxmin,issmall);
                    else h1=-max(hxmin-hxmax,issmall);
                    end
                    FFF=NN*((hxmax*log(xmax2)-hxmin*log(xmin2))/h1-1/(1-alph));
                case 2
                % EXPERIMENTAL ESTIMATOR FOR xmax and xmin .... 
                % REM: works quite badly!!!
                    lxx=length(xx);
                    hxhi=xx(3:lxx);
                    hxlo=xx(1:(lxx-2));
                    hxmid=xx(2:(lxx-1));
                    hf1=(hxhi-hxlo).*hxmid.^(1-alph);
                    hf2=hf1.*log(hxmid);
                    FFF=NN*sum(hf2)/sum(hf2);
                otherwise
                    error('... this should never happen!');
            end
        end
        val=abs(QQQ-FFF);
        if ~isnan(val); d(count)=val; else, d(count)=Inf; end
    end
    if isempty(d)
        msg=['dalpha too small -> break loop: ', dalph, ' !!!\n']; 
        runinfo=[runinfo msg];             
        if infoflg==1, fprintf(1,msg); end
        break; 
    end
    v=find(d==min(d));
    alphbest=alphav(v(1));
    new_dalph=4*dalph/Ninc;
    alphav=(alphbest-2*dalph):new_dalph:(alphbest+2*dalph);
    if dalph<eps, break; end
    dalph=new_dalph;
end
    
    
