function autoArrangeFigures(m, n, monitor_id, hExclude)
% INPUT  :
%        M : number of grid of vertical direction
%        N : number of grid of horizontal direction
% OUTPUT :
%
% get every figures that are opened now and arrange them.
%
% autoArrangeFigures selects automatically Monitor1.
% If you are dual(or more than that) monitor user, I recommend to set wide
% monitor as Monitor1.
%
% if you want arrange automatically, type 'autoArrangeFigures(0,0)' or 'autoArrangeFigures()'. 
%    But maximum number of figures for automatic mode is 27.
%
% if you want specify grid for figures, give numbers for parameters.
%    but if your grid size is smaller than required one for accommodating
%    all figures, this function changes to automatic mode and if more
%    figures are opend than maximum number, then it gives error.
%
% Notes
%  + 2017.1.20 use monitor id(Adam Danz's idea)
%
% leejaejun, Koreatech, Korea Republic, 2014.12.13
% jaejun0201@gmail.com

% mgc change notes
% changed inputs NH and NW to m,n to mimic subplot
% added default monitor_id = 1
% added 'mac' input parsing
% added remove non visible figs from fig count


if nargin < 2
    m = 0;
    n = 0;
    monitor_id = 1;
end

% mgc
if nargin == 2
    monitor_id = 1;
end

if nargin < 4
    hExclude = [];
    if ~isnumeric(monitor_id) && monitor_id == "mac" % mgc
       monitor_id = 1;
    end
end

task_bar_offset = [30 50];

%%
N_FIG = m * n;
if N_FIG == 0
    autoArrange = 1;
else
    autoArrange = 0;
end
figHandle = sortFigureHandles(findobj('Type','figure'));
figHandle = figHandle(~ismember(figHandle,hExclude));
figHandle = figHandle([figHandle.Visible] == "on"); % mgc 
n_fig = size(figHandle,1);
if n_fig <= 0
    warning('figures are not found');
    return
end

screen_sz = get(0,'MonitorPositions');
screen_sz = screen_sz(monitor_id, :);
scn_w = screen_sz(3) - task_bar_offset(1);
scn_h = screen_sz(4) - task_bar_offset(2);
scn_w_begin = screen_sz(1) + task_bar_offset(1);
scn_h_begin = screen_sz(2) + task_bar_offset(2);

if autoArrange==0
    if n_fig > N_FIG
        autoArrange = 1;
        warning('too many figures than you told. change to autoArrange');
    else
        nh = m;
        nw = n;
    end
end

if autoArrange == 1
    grid = [2 2 2 2 2 3 3 3 3 3 3 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4 4;
            3 3 3 3 3 3 3 3 4 4 4 5 5 5 5 5 5 5 5 6 6 6 7 7 7 7 7]';
   
    if n_fig > length(grid)
        warning('too many figures(maximum = %d)',length(grid))
        return
    end
    
    if scn_w > scn_h
        nh = grid(n_fig,1);
        nw = grid(n_fig,2);
    else
        nh = grid(n_fig,2);
        nw = grid(n_fig,1);
    end
end


fig_width = scn_w/nw;
fig_height = scn_h/nh;

fig_cnt = 1;
for i=1:1:nh
    for k=1:1:nw
        if fig_cnt>n_fig
            return
        end
        fig_pos = [scn_w_begin+fig_width*(k-1) ...
            scn_h_begin+scn_h-fig_height*i ...
            fig_width ...
            fig_height];
        set(figHandle(fig_cnt),'OuterPosition',fig_pos);
        fig_cnt = fig_cnt + 1;
    end
end

end

function figSorted = sortFigureHandles(figs)
    [tmp, idx] = sort([figs.Number]);
    figSorted = figs(idx);
end