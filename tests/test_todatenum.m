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

% %% Test error handling
%
% % This uses the custom local functions to mimic the testsuite features like
% % verifyError in a script-based testing framework. See the try-catch versions
% % further down for another way to test error handling.
%
% testdiag = "description of this test";
% eid = 'matfunclib:libname:todatenum';
%
% % verify failure
% assertError(@() todatenum('inputs that error'), eid, testdiag)
%
% % verify success
% assertSuccess(@() todatenum('inputs that dont error'), eid, testdiag)
%
% %% Test type handling
%
% % Test different types, if the function is expected to handle them
%
% expected = []; % add expected value for double type
% assert(isequal(todatenum(X), expected));
%
% expected = []; % add expected value for single type
% assert(isequal(todatenum(single(X)), single(expected)));
%
% expected = []; % add expected value for logical type
% assert(isequal(todatenum(logical(X)), expected));
%
% expected = []; % add expected value for int16 type
% assert(isequal(todatenum(int16(X)), expected)); % int16
%
% %% Test dimension handling
%
% % Test different dimensions
% assert(isequal(todatenum([2 3]), [4 6])); % 1D array
% assert(isequal(todatenum([2 3; 4 5]), [4 6; 8 10])); % 2D array
%
% %% Test empty inputs
% try
%    todatenum();
%    error('Expected an error for empty inputs, but none was thrown');
% catch ME
%    assert(strcmp(ME.identifier, 'MATLAB:minrhs'));
% end
%
% %% Test invalid inputs
% try
%    todatenum('invalid');
%    error('Expected an error for invalid inputs, but none was thrown');
% catch ME
%    % if arguments block is used:
%    assert(strcmp(ME.identifier, 'MATLAB:validation:UnableToConvert'));
%    % otherwise, might be:
%    % assert(strcmp(ME.identifier, 'MATLAB:invalidInput'));
% end
%
% %% Test too many input arguments
% try
%    todatenum(1,2,3,4,5,6,7);
%    error('Expected an error for too many inputs, but none was thrown');
% catch ME
%    assert(strcmp(ME.identifier, 'MATLAB:TooManyInputs'));
%    % if narginchk is used:
%    assert(strcmp(ME.identifier, 'MATLAB:narginchk:tooManyInputs'));
% end
%
