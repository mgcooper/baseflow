%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function q = fillnans(q,fmax)

% this is hard to follow but it works. it finds the nan segments <= fmax in
% length and then fills them. the part that's hard to follow is that it
% also finds the indices of the maximum number of non-nan elements
% bracketing the missing segment
   
    % mgc 8/12/21 nl should find nans of length <= nmax, not ==
    s   = [1;find(diff(isnan(q))==-1)+1];       % start non-nan segments
    e   = [find(diff(isnan(q))==1);length(q)];  % end non-nan segments
    nl  = find((s(2:end)-e(1:end-1)-1)<=fmax);  % nans of length nmax on s/e
    ni  = e((s(2:end)-e(1:end-1)-1)<=fmax)+1; % nans of length nmax on q
   %nl  = find((s(2:end)-e(1:end-1))==fmax+1);  % nans of length nmax on s/e
   %ni  = e((s(2:end)-e(1:end-1))==(fmax+1))+1; % nans of length nmax on q

    for i = 1:length(ni)
        si       = s(nl(i));                    % start of segment
        ei       = e(nl(i)+1);                  % end of segment
        q(si:ei) = fillmissing(q(si:ei),'spline');
    end
end