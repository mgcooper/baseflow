% test_nonnansegments
clearvars

nonnansegments = baseflow.privatefunction('nonnansegments');
%% test nonnansegments with no nans
x = [0, 1, 2, 3];
S_expected = 1;
E_expected = 4;
L_expected = 4;

[S, E, L] = nonnansegments(x);

assert(isequal(S, S_expected))
assert(isequal(E, E_expected))
assert(isequal(L, L_expected))

%% test nonnansegments with interior nans
x = [0, 1, 2, 3, nan, nan, nan, 1, 2, 3, 4];
S_expected = [1; 8];
E_expected = [4; 11];
L_expected = [4; 4];

[S, E, L] = nonnansegments(x);

assert(isequal(S, S_expected))
assert(isequal(E, E_expected))
assert(isequal(L, L_expected))

% Tests below commented out because the version of nonnansegments in the
% baseflow toolbox assumes leading and trailing nans have been removed. TODO:
% merge matfunclib/libspatial/util/nonnansegments.m into the baseflow toolbox.

% %% test nonnansegments with left edge nan
% x = [nan, 1, 2, 3];
% S_expected = 2;
% E_expected = 4;
% L_expected = 3;
% 
% [S, E, L] = nonnansegments(x);
% 
% assert(isequal(S, S_expected))
% assert(isequal(E, E_expected))
% assert(isequal(L, L_expected))
% 
% %% test nonnansegments with right edge nan
% x = [1, 2, 3, nan];
% S_expected = 1;
% E_expected = 3;
% L_expected = 3;
% 
% [S, E, L] = nonnansegments(x);
% 
% assert(isequal(S, S_expected))
% assert(isequal(E, E_expected))
% assert(isequal(L, L_expected))
% 
% %% test nonnansegments with both edge nan
% 
% x = [nan, 1, 2, 3, nan];
% S_expected = 2;
% E_expected = 4;
% L_expected = 3;
% 
% [S, E, L] = nonnansegments(x);
% 
% assert(isequal(S, S_expected))
% assert(isequal(E, E_expected))
% assert(isequal(L, L_expected))
% 
% 
% %% test nonnansegments with edge and interior nans
% 
% x = [nan, 1, 2, 3, nan, nan, nan, 1, 2, 3, nan];
% S_expected = [2; 8];
% E_expected = [4; 10];
% L_expected = [3; 3];
% 
% [S, E, L] = nonnansegments(x);
% 
% assert(isequal(S, S_expected))
% assert(isequal(E, E_expected))
% assert(isequal(L, L_expected))