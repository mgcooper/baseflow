%TEST_TODATENUM Test baseflow/private/todatenum.

% Define test data
T = datetime(1,1,1);

todatenum = baseflow.privatefunction('todatenum');

%% Test function accuracy with one input

% Test function accuracy using assert
expected = datenum(T); %#ok<*DATNM>
returned = todatenum(T);
assert(isequal(returned, expected));

%% Test with edge cases (Inf, NaN, very large/small numbers)
assert(isnan(todatenum(NaN)));
assert(isinf(todatenum(Inf)));
assert(abs(todatenum(1e200) - 1e200) < 1e-10); % replace with theoretical result

%% Test function accuracy with multiple inputs

expected = datenum(T);
returned = cell(1, 3);
[returned{1}, returned{2}, returned{3}] = todatenum(T, T, T);

cellfun(@(ret, exp) assert(isequal(ret, expected)), returned);
